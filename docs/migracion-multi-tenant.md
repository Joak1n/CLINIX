# Migración a Supabase compartido multi-tenant

## Objetivo
Pasar de "un proyecto Supabase por consultorio" a **un solo proyecto**
que aloja a todos los consultorios, aislados entre sí mediante
`consultorio_id` + Row Level Security (RLS) real, respaldada por
Supabase Auth (no por nuestra tabla `usuarios` con hash manual).

Con esto:
- Ya no necesitas un proyecto Supabase "central" por separado — la
  tabla `consultorios` vive en el mismo proyecto compartido.
- Un solo proyecto (gratis al inicio, luego un Pro de $25/mes cuando
  haga falta) sirve a todos tus clientes, no uno por cliente.

## Por qué Supabase Auth es obligatorio aquí
RLS solo es seguridad real si Postgres puede saber **quién** hace cada
petición. Con la anon key compartida por todos los dispositivos (como
hoy), una política tipo `WHERE consultorio_id = X` no protege nada: X
lo manda el cliente, y cualquiera podría mandar el de otro consultorio.
Con Supabase Auth, cada peticón lleva un JWT verificado por Supabase, y
las políticas usan `auth.uid()` — que el cliente NO puede falsificar.

## Tablas nuevas

### `consultorios` (reemplaza al proyecto "central")
```sql
create table consultorios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  telefono text,
  direccion text,
  codigo_acceso text unique not null,
  logo_url text,
  color_primario text,
  created_at timestamptz not null default now()
);
```

### `membresias` (reemplaza a la tabla `usuarios` actual)
Vincula un usuario de Supabase Auth con uno o más consultorios y su rol
dentro de cada uno. Un mismo usuario podría, en teoría, pertenecer a
más de un consultorio (por ejemplo, alguien que trabaja en dos
clínicas), aunque para tu caso normalmente será 1 a 1.
```sql
create table membresias (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  consultorio_id uuid not null references consultorios(id) on delete cascade,
  nombre text not null,
  rol text not null check (rol in ('admin', 'terapeuta', 'recepcion')),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  unique (usuario_id, consultorio_id)
);
```

### Función de ayuda para las políticas
```sql
create or replace function mis_consultorios()
returns setof uuid
language sql
security definer
stable
as $$
  select consultorio_id from membresias
  where usuario_id = auth.uid() and activo = true;
$$;
```
`security definer` + `stable` para que sea rápida y no se pueda
manipular desde el cliente.

## Tablas existentes: qué cambia
A **cada** tabla de negocio (pacientes, citas, notas_clinicas,
notas_internas, historia_clinica, signos_vitales, horarios_atencion,
bloqueos_horario, especialidades, bitacora_sesiones, auditoria,
consentimientos_informados, adjuntos) se le agrega:
```sql
alter table pacientes add column consultorio_id uuid not null
  references consultorios(id);
```
(mismo patrón para cada una — se entrega el script completo en el
siguiente paso).

## Políticas RLS (patrón general)
Para cada tabla:
```sql
alter table pacientes enable row level security;

create policy "ver solo mi consultorio"
  on pacientes for select
  using (consultorio_id in (select mis_consultorios()));

create policy "insertar en mi consultorio"
  on pacientes for insert
  with check (consultorio_id in (select mis_consultorios()));

create policy "editar en mi consultorio"
  on pacientes for update
  using (consultorio_id in (select mis_consultorios()));

create policy "eliminar en mi consultorio"
  on pacientes for delete
  using (consultorio_id in (select mis_consultorios()));
```
Mismo patrón para todas las tablas de negocio. `usuarios`/`membresias`
llevan políticas algo distintas (solo un admin puede crear/eliminar
membresías de su propio consultorio).

## Creación de usuarios: por qué necesita una Edge Function
Con Supabase Auth, crear un usuario nuevo (cuando un admin agrega a un
terapeuta) requiere la Admin API de Supabase, que solo funciona con la
`service_role key` — una llave con acceso TOTAL a la base de datos,
que **nunca** debe ir dentro de la app (cualquiera podría extraerla del
APK y saltarse todo RLS). Por eso ese paso se hace con una Edge
Function: corre en el servidor de Supabase, la app le llama con la
anon key normal, la función valida que quien llama es admin de ese
consultorio, y ahí sí usa la service_role key internamente (nunca
sale de la función).

## Próximo paso
Con este diseño aprobado, el siguiente paso es:
1. Escribir el script SQL completo (todas las tablas + políticas).
2. Escribir la Edge Function de creación de usuarios.
3. Empezar a migrar el código Flutter (auth_provider primero).
