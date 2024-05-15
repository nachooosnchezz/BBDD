CREATE TABLE empleados (
    id_empleado NUMBER PRIMARY KEY,
    nombre VARCHAR2(100),
    salario NUMBER,
    departamento VARCHAR2(100)
);

CREATE TABLE tareas (
    id_tarea NUMBER PRIMARY KEY,
    descripcion VARCHAR2(200),
    fecha_limite DATE,
    id_empleado NUMBER REFERENCES empleados(id_empleado)
);

CREATE TABLE clientes(
    id_cliente int primary key,
    nombre varchar2(100),
    apellidos varchar2(100)
    
);

CREATE TABLE pedidos (
    id_pedido NUMBER PRIMARY KEY,
    fecha_pedido DATE,
    id_cliente references clientes(id_cliente),
    estado varchar2(100)
);



CREATE TABLE proyectos (
    id_proyecto NUMBER PRIMARY KEY,
    nombre VARCHAR2(100),
    descripcion VARCHAR2(200),
    fecha_inicio DATE
    -- Otros campos relacionados con el proyecto...
);

CREATE TABLE horas_trabajadas (
    id_horas NUMBER PRIMARY KEY,
    id_proyecto NUMBER REFERENCES proyectos(id_proyecto),
    id_empleado NUMBER REFERENCES empleados(id_empleado),
    horas NUMBER,
    fecha DATE
    -- Otros campos relacionados con las horas trabajadas...
);
CREATE TABLE reservas (
    id_reserva NUMBER PRIMARY KEY,
    fecha_inicio DATE,
    fecha_fin DATE,
    recurso_reservado VARCHAR2(100)
    -- Otros campos relacionados con la reserva...
);

CREATE TABLE recursos (
    id_recurso NUMBER PRIMARY KEY,
    nombre VARCHAR2(100),
    cantidad_disponible NUMBER
    -- Otros campos relacionados con el recurso...
);


create or replace view V_HORAS_TRABAJADAS(idproyecto,nombreproyecto,idempleado,nombreempleado,horas_trabajadas) as
    select p.id_proyecto, p.nombre,e.id_empleado, e.nombre, sum(h.horas) from horas_trabajadas h
    join empleados e on e.id_empleado = h.id_empleado
    join proyectos p on p.id_proyecto = h.id_proyecto
    group by p.id_proyecto, p.nombre,e.id_empleado, e.nombre
;

select * from V_HORAS_TRABAJADAS;



create or replace view V_ESTADO_PEDIDOS(idpedido,fechapedido,nombrecliente,estado) as
    select p.id_pedido, p.fecha_pedido, c.nombre, p.estado from pedidos p 
    join clientes c on c.id_cliente = p.id_cliente
;

select * from V_ESTADO_PEDIDOS;




CREATE OR REPLACE PROCEDURE CALCULAR_SALARIO(
    p_idempleado IN number, 
    p_idproyecto IN number 
)as
    v_salario number;
    v_horas_pagadas number;
begin
    select salario into v_salario from empleados where id_empleado = p_idempleado;
    select sum(horas * (v_salario/horas)) into v_horas_pagadas from horas_trabajadas where id_empleado = p_idempleado and id_proyecto = p_idproyecto;
    dbms_output.put_line(v_horas_pagadas);
end;
/


declare
begin
    CALCULAR_SALARIO(1,1);
end;
/
set serveroutput on;



create or replace trigger ACTUALIZAR_ESTADO_PEDIDO
after insert on reservas
for each row
declare
    v_inicio date;
    v_final date;
begin
    select fecha_inicio into v_inicio from reservas where id_reserva = :new.id_reserva;
    select fecha_fin into v_final from reservas where id_reserva = :new.id_reserva;
    
    if v_inicio < v_final then
        raise_application_error(-20001,'La fecha inicial no puede ser posterior a la final');
    else 
        update pedidos set estado = 'En proceso' where id_pedido = :new.id_pedido;
    end if;

end;
/

