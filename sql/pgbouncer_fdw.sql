CREATE SCHEMA pgbouncer;

ALTER SCHEMA pgbouncer OWNER TO postgres;

CREATE VIEW pgbouncer.clients AS
 SELECT _.type,
    _."user",
    _.database,
    _.state,
    _.addr,
    _.port,
    _.local_addr,
    _.local_port,
    _.connect_time,
    _.request_time,
    _.wait,
    _.wait_us,
    _.close_needed,
    _.ptr,
    _.link,
    _.remote_pid,
    _.tls
   FROM public.dblink('pgbouncer'::text, 'show clients'::text) _(type text, "user" text, database text, state text, addr text, port integer, local_addr text, local_port integer, connect_time timestamp with time zone, request_time timestamp with time zone, wait integer, wait_us integer, close_needed integer, ptr text, link text, remote_pid integer, tls text);


ALTER TABLE pgbouncer.clients OWNER TO postgres;

CREATE VIEW pgbouncer.clients_session AS
 SELECT _.type,
    _."user",
    _.database,
    _.state,
    _.addr,
    _.port,
    _.local_addr,
    _.local_port,
    _.connect_time,
    _.request_time,
    _.wait,
    _.wait_us,
    _.close_needed,
    _.ptr,
    _.link,
    _.remote_pid,
    _.tls
   FROM public.dblink('pgbouncer_session'::text, 'show clients'::text) _(type text, "user" text, database text, state text, addr text, port integer, local_addr text, local_port integer, connect_time timestamp with time zone, request_time timestamp with time zone, wait integer, wait_us integer, close_needed integer, ptr text, link text, remote_pid integer, tls text);


ALTER TABLE pgbouncer.clients_session OWNER TO postgres;

CREATE VIEW pgbouncer.servers AS
 SELECT _.type,
    _."user",
    _.database,
    _.state,
    _.addr,
    _.port,
    _.local_addr,
    _.local_port,
    _.connect_time,
    _.request_time,
    _.wait,
    _.wait_us,
    _.close_needed,
    _.ptr,
    _.link,
    _.remote_pid,
    _.tls
   FROM public.dblink('pgbouncer'::text, 'show servers'::text) _(type text, "user" text, database text, state text, addr text, port integer, local_addr text, local_port integer, connect_time timestamp with time zone, request_time timestamp with time zone, wait integer, wait_us integer, close_needed integer, ptr text, link text, remote_pid integer, tls text);


ALTER TABLE pgbouncer.servers OWNER TO postgres;

CREATE VIEW pgbouncer.pool_activity AS
 SELECT a.pid,
    c.addr,
    a.usename AS "User",
    a.application_name AS app,
    a.state,
    c.connect_time,
    date_trunc('second'::text, a.query_start) AS query_start,
    substr(a.query, 1, 50) AS query
   FROM ((pgbouncer.clients c
     JOIN pgbouncer.servers s ON ((c.ptr = s.link)))
     JOIN pg_stat_activity a ON ((a.client_port = s.local_port)))
  ORDER BY a.usename, a.query_start;


ALTER TABLE pgbouncer.pool_activity OWNER TO postgres;

CREATE VIEW pgbouncer.servers_session AS
 SELECT _.type,
    _."user",
    _.database,
    _.state,
    _.addr,
    _.port,
    _.local_addr,
    _.local_port,
    _.connect_time,
    _.request_time,
    _.wait,
    _.wait_us,
    _.close_needed,
    _.ptr,
    _.link,
    _.remote_pid,
    _.tls
   FROM public.dblink('pgbouncer_session'::text, 'show servers'::text) _(type text, "user" text, database text, state text, addr text, port integer, local_addr text, local_port integer, connect_time timestamp with time zone, request_time timestamp with time zone, wait integer, wait_us integer, close_needed integer, ptr text, link text, remote_pid integer, tls text);


ALTER TABLE pgbouncer.servers_session OWNER TO postgres;

CREATE VIEW pgbouncer.pool_session_activity AS
 SELECT a.pid,
    c.addr,
    a.usename AS "User",
    a.application_name AS app,
    a.state,
    c.connect_time,
    date_trunc('second'::text, a.query_start) AS query_start,
    substr(a.query, 1, 50) AS query
   FROM ((pgbouncer.clients_session c
     JOIN pgbouncer.servers_session s ON ((c.ptr = s.link)))
     JOIN pg_stat_activity a ON ((a.client_port = s.local_port)))
  ORDER BY a.usename, a.query_start;


ALTER TABLE pgbouncer.pool_session_activity OWNER TO postgres;

CREATE VIEW pgbouncer.pools AS
 SELECT _.database,
    _."user",
    _.cl_active,
    _.cl_waiting,
    _.sv_active,
    _.sv_idle,
    _.sv_used,
    _.sv_tested,
    _.sv_login,
    _.maxwait,
    _.maxwait_us,
    _.pool_mode
   FROM public.dblink('pgbouncer'::text, 'show pools'::text) _(database text, "user" text, cl_active integer, cl_waiting integer, sv_active integer, sv_idle integer, sv_used integer, sv_tested integer, sv_login integer, maxwait integer, maxwait_us integer, pool_mode text);


ALTER TABLE pgbouncer.pools OWNER TO postgres;

CREATE VIEW pgbouncer.pools_session AS
 SELECT _.database,
    _."user",
    _.cl_active,
    _.cl_waiting,
    _.sv_active,
    _.sv_idle,
    _.sv_used,
    _.sv_tested,
    _.sv_login,
    _.maxwait,
    _.maxwait_us,
    _.pool_mode
   FROM public.dblink('pgbouncer_session'::text, 'show pools'::text) _(database text, "user" text, cl_active integer, cl_waiting integer, sv_active integer, sv_idle integer, sv_used integer, sv_tested integer, sv_login integer, maxwait integer, maxwait_us integer, pool_mode text);


ALTER TABLE pgbouncer.pools_session OWNER TO postgres;
