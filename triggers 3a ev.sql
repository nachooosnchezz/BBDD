create or replace trigger CONTROL_PRECIOS_ENTRADA
before insert on compra
for each row
declare
    -- VARIABLES QUE HAGAN FALTA
    v_ultimopreciocompra number;
begin
    select ultimopreciocompra into v_ultimopreciocompra from v_existencias where idproducto = :new.id_producto;
        
    if v_ultimopreciocompra is not null then
        if :new.precio_proveedor > v_ultimopreciocompra + 10 or :new.precio_proveedor < v_ultimopreciocompra - 10 then
            RAISE_APPLICATION_ERROR(-20200, 'PRECIOFUERADERANGO');
        end if;
    end if;
end;
/

-- PRUEBA DEL TRIGGER
declare
    id number;
begin
crear_producto( 'Pera limonera', id );
entrada_producto( id, 1, 10); -- COMPRO 1 A 10e, ADMITIDO POR SER LA PRIMERA
entrada_producto( id, 3, 20); -- COMPRO 3 A 20e, ADMITIDO
entrada_producto( id, 2, 9); -- COMPRO 2 A 9e, DEBERIA DAR ERROR
end;
/




create table T_SALDO(
    saldo number(10,2)
);


create or replace trigger TRIGGERENTRADA
after insert on compra
for each row
declare
begin
    -- Actualizamos el saldo restando el dinero gastado en la compra
    update T_SALDO set saldo = nvl(saldo, 0) - (:new.cantidad * :new.precio_proveedor);
    
    -- Si no hay ninguna fila en T_SALDO, creamos una nueva fila con el saldo actualizado
    if sql%notfound then
        insert into T_SALDO values (:new.cantidad * :new.precio_proveedor * -1);
    end if;
end;
/

-- Creamos el trigger para la tabla venta (salida de productos)
create or replace trigger TRIGGERSALIDA
after insert on venta
for each row
declare
begin
    -- Actualizamos el saldo sumando el dinero obtenido por la venta
    update T_SALDO set saldo = nvl(saldo, 0) + (:new.cantidad * :new.precio_unidad);
    -- Si no hay ninguna fila en T_SALDO, creamos una nueva fila con el saldo actualizado
    if sql%notfound then
        insert into T_SALDO values (:new.cantidad * :new.precio_unidad);
    end if;
end;
/


-- Creamos la tabla T_SALDO
create table T_SALDO (
    saldo number(10,2)
);

-- Creamos el trigger para la tabla compra (entrada de productos)
create or replace trigger TRIGGERENTRADA
after insert on compra
for each row
begin
    -- Actualizamos el saldo restando el dinero gastado en la compra
    update T_SALDO set saldo = nvl(saldo, 0) - (:new.cantidad * :new.precio_proveedor);
    -- Si no hay ninguna fila en T_SALDO, creamos una nueva fila con el saldo actualizado
    if sql%notfound then
        insert into T_SALDO values (:new.cantidad * :new.precio_proveedor * -1);
    end if;
end;
/

-- Creamos el trigger para la tabla venta (salida de productos)
create or replace trigger TRIGGERSALIDA
after insert on venta
for each row
begin
    -- Actualizamos el saldo sumando el dinero obtenido por la venta
    update T_SALDO set saldo = nvl(saldo, 0) + (:new.cantidad * :new.precio_unidad);
    -- Si no hay ninguna fila en T_SALDO, creamos una nueva fila con el saldo actualizado
    if sql%notfound then
        insert into T_SALDO values (:new.cantidad * :new.precio_unidad);
    end if;
end;
/

    

create or replace trigger INSERTAR_PRODUCTO_VISTA
instead of INSERT on V_EXISTENCIAS
for each row
declare
    v_idproducto number;
begin
    -- Verificamos si se proporciona un valor para NOMBREPRODUCTO
    if :new.nombreproducto is null then
        -- Si no se proporciona, lanzamos un error
        raise_application_error(-20104, 'FALTANDATOS: Se requiere el nombre del producto.');
    end if;

    -- Si se proporciona un valor para IDPRODUCTO
    if :new.idproducto is not null then
        -- Verificamos si el IDPRODUCTO ya existe en la tabla de productos
        select count(*) into v_idproducto from productos where id_producto = :new.idproducto;
        if v_idproducto > 0 then
            -- Si el IDPRODUCTO ya existe, lanzamos un error
            raise_application_error(-20103, 'PRODUCTOYAEXISTE: El ID de producto ya está en uso.');
        end if;
    else
        -- Si no se proporciona un valor para IDPRODUCTO, obtenemos uno nuevo de la secuencia
        v_idproducto := nuevo_id_producto.nextval;
        -- Verificamos si el IDPRODUCTO generado ya existe en la tabla de productos
        while true loop
            select count(*) into v_idproducto from productos where id_producto = v_idproducto;
            exit when v_idproducto = 0;
            v_idproducto := nuevo_id_producto.nextval;
        end loop;
    end if;

    -- Insertamos el nuevo producto con los datos proporcionados
    insert into productos (id_producto, nombre, stock) values (v_idproducto, :new.nombreproducto, :new.existencias);

    -- Insertamos la entrada de producto con la cantidad indicada y el precio de compra indicado
    insert into compra (id_compra, id_producto, cantidad, precio_proveedor) 
    values (nuevo_id_compra.nextval, v_idproducto, :new.existencias, :new.ultimopreciocompra);
end;
/
    
    

create or replace view V_EXISTENCIAS(
    idproducto,
    nombreproducto,
    existencias,
    ultimopreciocompra,
    ultimoprecioventa
) as
select 
    p.id_producto,
    p.nombre,
    COALESCE(p.stock, 0), -- Si p.stock es NULL, se reemplaza con 0
    COALESCE((
        SELECT c.precio_proveedor
        FROM compra c 
        WHERE c.id_producto = p.id_producto 
        order by id_compra desc
        fetch first row only
    ), NULL), -- Utilizamos COALESCE para establecer NULL si no hay registro de compra
    COALESCE((
        SELECT v.precio_unidad
        FROM venta v 
        WHERE v.id_producto = p.id_producto
        order by id_venta desc
        fetch first row only
    ), NULL) -- Utilizamos COALESCE para establecer NULL si no hay registro de venta
FROM productos p;



create or replace trigger crear_todos_clientes
instead of insert on todos_clientes
for each row
declare
    v_idcliente number;
    v_secuencia number;
begin
    if :new.idcliente is not null then
        RAISE_APPLICATION_ERROR(-20002,'SOBRANDATOS');
    end if;
    
    loop 
        v_idcliente := nuevoidcliente.nextval;
        select count(*) into v_secuencia from cen_clientes where idcliente = v_idcliente;
        exit when v_secuencia = 0;
    end loop;
    
    if :new.localizacion = 'C' then
        insert into t_cen_clientes values (v_idcliente, :new.nombrecliente);
    end if;
    
    if :new.localizacion = 'S' then
        insert into t_suc_clientes@sucursal_central values (v_idcliente, :new.nombrecliente);
    end if;
end;
/


create or replace trigger modificar_cliente
instead of update on todos_clientes
for each row
declare
    v_idcliente number;
    v_secuencia number;
begin
    if :new.idcliente = :old.idcliente then
        RAISE_APPLICATION_ERROR(-20003,'INMUTABLE');
    end if;
    if :new.nombrecliente = :old.nombrecliente then
        RAISE_APPLICATION_ERROR(-20004,'INMUTABLE');
    end if;
    loop 
        v_idcliente := nuevoidcliente.nextval;
        select count(*) into v_secuencia from cen_clientes where idcliente = v_idcliente;
        exit when v_secuencia = 0;
    end loop;
    if :new.localizacion = 'S' or :old.localizacion = 'C' then
        insert into t_suc_clientes@sucursal_central values (v_idcliente, :new.nombrecliente);
        delete from t_cen_clientes where idcliente = :new.idcliente and nombrecliente = :NEW.nombrecliente;
    end if;
    
     if :new.localizacion = 'C' or :old.localizacion = 'S' then
        insert into t_cen_clientes values (v_idcliente, :new.nombrecliente);
        delete from t_suc_clientes@sucursal_central where idcliente = :new.idcliente and nombrecliente = :NEW.nombrecliente;

    end if;
end;
/
