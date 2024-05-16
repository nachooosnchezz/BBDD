create table personas(
    idpersona numeric(10) primary key,
    nombre varchar2(255),
    apellidos varchar2(255),
    padre references personas(idpersona),
    madre references personas(idpersona), 
    fallecido numeric(1)
);

drop table personas;

--vistas

create or replace EDITIONABLE view V_PERSONAS(
    idpersona,
    nombre,
    apellidos,
    fallecida
)as(
    select idpersona, nombre, apellidos, fallecido
    from personas
);

select * from V_PERSONAS;

create or replace EDITIONABLE view V_PROGENITORES (
    idpersona,
    nombremadre,
    apellidosmadre,
    nombrepadre,
    apellidospadre
)as(
    select h.idpersona, m.nombre, m.apellidos, p.nombre,p.apellidos from personas h
    join personas m on nvl(m.idpersona,0) = h.madre
    join personas p on nvl(p.idpersona,0) = h.padre
);




create or replace view V_PROGENITORES (
    idpersona,
    idmadre,
    nombremadre,
    apellidosmadre,
    idpadre,
    nombrepadre,
    apellidospadre
)as(
    select h.idpersona,m.idpersona, m.nombre, m.apellidos,p.idpersona, p.nombre, p.apellidos from personas h
    left join personas m on nvl(m.idpersona,0) = h.madre
    left join personas p on nvl(p.idpersona,0) = h.padre
);




select * from v_progenitores;



create or replace trigger REGISTRO_PERSONA
instead of insert on V_PERSONAS
for each row
declare 
    v_existe number;
begin
    select count(*) into v_existe from personas where idpersona = :new.idpersona;
    if v_existe <> 0 then
        raise_application_error(-20001,'PERSONAYAEXISTE');
    end if;
    
    if :new.idpersona is null then
            raise_application_error(-20002,'IDNECESARIO');        
        end if;

    if :new.fallecida is null then
        update v_personas set fallecida = 0 where idpersona = :new.idpersona;
    end if;
    
    insert into personas (idpersona,nombre,apellidos,fallecido) values (:new.idpersona, :new.nombre, :new.apellidos, :new.fallecida);
    
end;
/

select * from v_personas;

insert into v_personas (idpersona,nombre,apellidos) values (10,'Marta','sanchez lopez');

create or replace function SIGUIENTE_IDPERSONA
return numeric
as
begin
    
end;
/

create sequence secuencia_idpersona START WITH 1 INCREMENT BY 1;





create or replace trigger AFILIACION_PERSONAS 
instead of update on v_progenitores
for each row
declare
    v_nombre_comun number;
    v_idmadre number;
begin
    if :new.nombremadre is null then
        update personas set madre = null where idpersona = :new.idpersona;
    end if;
    
    if :new.nombrepadre is null then
        update personas set padre = null where idpersona = :new.idpersona;
    end if;
    
    select madre into v_idmadre from personas where idpersona = :new.idpersona;
    if :new.nombremadre is not null then
        select count(*) into v_nombre_comun from personas where nombre = :new.nombremadre;
        if v_nombre_comun = 1 then
            update personas set madre = v_idmadre where idpersona = :new.idpersona;
        end if;
    end if;
end;
/

insert into




















-- secuencias

create sequence nuevo_id_persona start with 4;
-- procedimientos
create or replace procedure REGISTRA_PERSONA(
    p_nombre in varchar2,
    p_apellidos in varchar2,
    p_idpersona out numeric
)as
    v_personas personas%rowtype;
begin
    p_idpersona := NUEVO_ID_PERSONA.nextval;
    
    v_personas.idpersona := p_idpersona ;
    v_personas.nombre := p_nombre ;
    v_personas.apellidos := p_apellidos ;
    v_personas.fallecido := 0 ;
    
    insert into personas values v_personas;
end;
/

declare 
    v_idpersona numeric;
begin
    REGISTRA_PERSONA('Alejandro','Sanchez Lopez', v_idpersona );
end;
/



create or replace procedure registra_fallecimiento(
    p_idpersona in numeric
)as
    v_existe number;
    v_fallecida number;
begin

    select count(*) into v_existe from personas where idpersona = p_idpersona;

    select sum(fallecido) into v_fallecida from personas where idpersona = p_idpersona;

    if v_existe = 0 or v_existe is null or v_fallecida is null then
        raise_application_error(-20001,'La persona no está registrada');
    end if;
    
    if v_fallecida = 1 then
        raise_application_error(-20002,'La persona ya está fallecida');
    else
        update personas set fallecido = 1 where idpersona = p_idpersona;        
    end if;

end;
/


declare
begin
    REGISTRA_FALLECIMIENTO(1);
end;
/


create or replace procedure cambia_afiliacion(
    p_idpersona in numeric,
    p_idprogenitor in numeric,
    p_padreomadre in varchar2
)as
    v_existehijo number;
    v_existeprogenitor number;
begin
    select count(*) into v_existehijo from personas where idpersona = p_idpersona;
    select count(*) into v_existeprogenitor from personas where idpersona = p_idprogenitor ;
    
    if v_existehijo = 0 or v_existehijo is null then
        raise_application_error(-20001,'No existe persona, cambie la persona');
    end if;
    
    if v_existeprogenitor = 0 or v_existeprogenitor is null then
        raise_application_error(-20001,'No existe persona, cambie el progenitor');
    end if;
    
    if upper(p_padreomadre) like 'MADRE' then
        update personas set madre = p_idprogenitor where idpersona = p_idpersona;
    end if;
    
    if upper(p_padreomadre) like 'PADRE' then
        update personas set padre = p_idprogenitor where idpersona = p_idpersona;
    end if;
end;
/

declare 
begin
    CAMBIA_AFILIACION(3,1,'madre');
end;
/

-- funciones

create or replace function es_huerfano(
    p_idpersona number
)return number
as
    v_existe number;
    v_padre number;
    v_madre number;
begin
    select count(*) into v_existe from personas where idpersona = p_idpersona;
    if v_existe = 0 or v_existe is null then
        raise_application_error(-20001, 'La persona no existe');
    end if;
    
    -- estado del padre
    select p.fallecido into v_padre from personas h 
    join personas p on p.idpersona =h.padre
    where h.idpersona = p_idpersona;
    -- estado de la madre
    select m.fallecido into v_madre from personas h 
    join personas m on m.idpersona =h.madre
    where h.idpersona = p_idpersona;
    
    
    if v_padre = 1 and v_madre = 1 then
        return 1;
    end if;
    if v_padre = 0 and v_madre = 1 then
        return 0;
    end if;
    
    if v_padre = 1 and v_madre = 0 then
        return 0;
    end if;
    
    if v_padre = 0 and v_madre = 0 then
        return 0;
    end if;
end;
/

update personas set fallecido = 1 where idpersona= 2;

set serveroutput on;

declare
begin
dbms_output.put_line(ES_HUERFANO(3));
end;
/

select * from v_personas;