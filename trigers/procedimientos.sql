-- crear un cliente y los campos NULL se llaman "por definir"
create or replace procedure crear_cliente(p_nombre varchar, p_idcliente out number)
as
    v_existe number;
    v_clientes clientes%rowtype;
begin
    -- secuencia para el id de cliente
     p_idcliente := nuevo_id_cliente.nextval;
    
    -- verificar existencia del cliente
    select count(*) into v_existe from clientes where codigocliente = p_idcliente;
    if v_existe = 0 then
        raise_application_error(-20001,'El cliente ' || p_idcliente || ' no existe');
    else
        v_clientes.codigocliente := p_idcliente;
        v_clientes.nombrecliente := p_nombre ;
        insert into clientes values v_clientes;
    end if;
    
update clientes 
set 
    nombrecontacto = coalesce(nombrecontacto, 'por definir'),
    telefono = coalesce(telefono, 'por definir'),
    fax = coalesce(fax, 'por definir'),
    lineadireccion1 = coalesce(lineadireccion1, 'por definir'),
    lineadireccion2 = coalesce(lineadireccion2, 'por definir'),
    ciudad = coalesce(ciudad, 'por definir'),
    region = coalesce(region, 'por definir'),
    pais = coalesce(pais, 'por definir'),
    codigopostal = coalesce(codigopostal, 'por definir'),
    codigoempleadorepventas = coalesce(codigoempleadorepventas, -1),
    limitecredito = coalesce(limitecredito, -1)
where codigocliente = p_idcliente;

end;
/

create sequence nuevo_id_cliente increment by 1;

-- llamar al procedimiento
declare
    v_id_cliente NUMBER;
begin
    -- Llamada al procedimiento crear_cliente
    crear_cliente('nombre del cliente', v_id_cliente);
    
    -- El ID del cliente creado estará almacenado en v_id_cliente
    DBMS_OUTPUT.PUT_LINE('se creó el cliente con id: ' || v_id_cliente);
end;
/


-- crea un pedido para el cliente, con fecha de hoy, fecha esperada dentro de una semana, estado a 'NUEVO'.
create or replace procedure CREAR_PEDIDO(p_idcliente number, p_idpedido out number)
as
    v_existe number;
    v_pedidos pedidos%rowtype;
begin
    -- almacenar el nuevo id del pedido
        p_idpedido := nuevo_id_pedido.nextval;
        
    --verificar si existe
    select count(*) into v_existe from pedidos where codigopedido = p_idpedido;
    if v_existe <> 0 or v_existe is not null then
        raise_application_error(-20002,'el pedido ' || p_idpedido || ' ya existe');
    end if;
    
    -- almacenar datos en la variable v_pedidos
        v_pedidos.codigopedido := p_idpedido;
        v_pedidos.fechapedido :=  sysdate ;
        v_pedidos.fechaesperada := sysdate + 7;
        v_pedidos.estado := 'nuevo';
        v_pedidos.codigocliente := p_idcliente;

        insert into pedidos values v_pedidos;
    
end;
/
create sequence nuevo_id_pedido increment by 1 start with 129;

declare 
    v_idpedido number;
begin
    crear_pedido(10,v_idpedido);
    
    dbms_output.put_line('id pedido: ' || v_idpedido);
end;
/


-- Crea una línea de pedido, con el precio del catálogo. El número de línea será el de la última línea más uno.
create or replace procedure crear_linea_pedido(
    p_idpedido in number, 
    p_idproducto in varchar2, 
    p_cantidad in number
)as
    v_lineapedido detallepedidos%rowtype;
    v_existepedido number;
    v_existeproducto number;
    v_preciounidad number;
    v_numerolinea number;
begin
    --verificar que el pedido existe
    select count(*) into v_existepedido from pedidos where p_idpedido = codigopedido;
    if v_existepedido = 0 or v_existepedido is null then
        raise_application_error(-20002,'el pedido ' || p_idpedido || ' no existe');
    end if;
    
    -- verificar que el producto existe
    select count(*) into v_existeproducto from productos where codigoproducto = p_idproducto;
    if v_existeproducto = 0 or v_existeproducto is null then
        raise_application_error(-20003,'el producto ' || p_idproducto || ' no existe');
    end if;
    
    select precioventa into v_preciounidad from productos where codigoproducto = p_idproducto;
    select max(numerolinea) + 1 into v_numerolinea from detallepedidos where p_idpedido = codigopedido;
    
    if v_numerolinea is null then
        v_numerolinea := 1;
    end if;
    
    if v_numerolinea <> 0 or v_numerolinea is not null then
        select max(numerolinea) + 1 into v_numerolinea from detallepedidos where p_idpedido = codigopedido;
    end if;
    
    v_lineapedido.codigopedido := p_idpedido ;
    v_lineapedido.codigoproducto := p_idproducto;
    v_lineapedido.cantidad := p_cantidad;
    v_lineapedido.preciounidad := v_preciounidad ;
    v_lineapedido.numerolinea := v_numerolinea ;

    insert into detallepedidos values v_lineapedido;
end;
/


DECLARE
    v_idpedido NUMBER := 118; -- Ingresa el ID del pedido
    v_idproducto varchar2(50) := 'FR-100'; -- Ingresa el ID del producto
    v_cantidad NUMBER := 6; -- Ingresa la cantidad del producto

BEGIN
    -- Llamada al procedimiento crear_linea_pedido
    crear_linea_pedido(v_idpedido, v_idproducto, v_cantidad);
    
    -- Si quieres mostrar un mensaje de confirmación
    DBMS_OUTPUT.PUT_LINE('Línea de pedido creada exitosamente.');
    
    -- Si deseas hacer alguna otra operación después de llamar al procedimiento
    
END;
/

select * from detallepedidos where codigopedido = 115;


-- Devuelve el precio que el cliente tiene que pagar por el pedido

create or replace procedure PRECIO_PEDIDO(
    p_idpedido in integer
)as
    v_existe number;
    v_producto number;
begin
    select count(*) into v_existe from pedidos where p_idpedido = codigopedido;
    if v_existe = 0 or v_existe is null then
        raise_application_error(-20005,'el pedido ' || p_idpedido || ' no existe');
    end if;
    
    v_producto := PRECIO_DE_PEDIDO(p_idpedido);
end;
/

create or replace function precio_de_pedido(p_idpedido in integer)
return number
as
    v_precio number;
begin
    select (cantidad * preciounidad) into v_precio from detallepedidos where p_idpedido = codigopedido;
    return v_precio;
end;
/

declare
    v_idpedido integer := 100;
begin
    PRECIO_PEDIDO(v_idpedido);
end;
/



-- Crea un procedimiento almacenado que calcule el promedio de ventas en un mes determinado.

create or replace procedure crear_cliente(
    p_idcliente out number,
    p_nombre varchar2,
    p_telefono number
)as
    v_clientes clientes%rowtype;
begin
    p_idcliente := s_nuevo_id_cliente.nextval;
    
    v_clientes.codigocliente := p_idcliente;
    v_clientes.nombrecliente := p_nombre ;
    v_clientes.telefono := p_telefono ;
    v_clientes.codigoempleadorepventas := 100000;
    v_clientes.limitecredito := 0;
    
    insert into clientes values v_clientes;
end;
/

create sequence s_nuevo_id_cliente start with 39;

declare
    v_idcliente number;
begin
    crear_cliente(v_idcliente,'Alfedro',601422411);
end;
/
-- Escribe un procedimiento almacenado que calcule el total de compras de un cliente específico.

create or replace procedure total_ventas_cliente(
    p_idcliente number
)as
    v_total_ventas number;
begin
    select count(*) into v_total_ventas from pedidos where codigocliente = p_idcliente;
    if v_total_ventas <> 0 then
        dbms_output.put_line('El cliente ' || p_idcliente || ' ha realizado un total de ' || v_total_ventas || ' compras' );
    else
        raise_application_error(-20010,'El cliente no tiene ventas');
    end if;
    
end;
/



declare 
begin
    TOTAL_VENTAS_CLIENTE(38);
end;
/


-- crea un pedido rapido con una unidad de producto,el identificador del pedido se devuelve en un parameto de salida

create or replace procedure ONE_CLICK_BUY(
    p_idcliente number,
    p_idproducto varchar2,
    p_idpedido out number
)as
    v_existe_cliente number;
    v_existe_producto number;
    v_pedido pedidos%rowtype;
    v_dp detallepedidos%rowtype;
    v_numerolinea number;
    v_precio_producto productos.precioventa%type;
begin
    p_idpedido := s_nueva_unidad_producto.nextval;
    
    select count(*) into v_existe_cliente from clientes where codigocliente = p_idcliente;
    select count(*) into v_existe_producto from productos where codigoproducto = p_idproducto;
    
    if v_existe_cliente = 0 or v_existe_cliente is null then
        raise_application_error(-20001,'El cliente no existe');
    end if;
    
    if v_existe_producto = 0 or v_existe_producto is null then
        raise_application_error(-20002, 'El producto no existe');
    end if;
    
    -- insertar datos de pedido
    v_pedido.codigopedido := p_idpedido;
    v_pedido.fechapedido := sysdate ;
    v_pedido.fechaesperada := sysdate + 7 ;
    v_pedido.estado := 'Pendiente' ;
    v_pedido.codigocliente := p_idcliente;
    insert into pedidos values v_pedido;
    
    -- insertar datos en detallepedidos
    select max(numerolinea) + 1 into v_numerolinea from detallepedidos where p_idpedido = codigopedido;
    
     if v_numerolinea is null then
        v_numerolinea := 1;
    end if;
    
    select precioventa into v_precio_producto from productos where codigoproducto = p_idproducto;
    
    v_dp.codigopedido := p_idpedido;
    v_dp.codigoproducto := p_idproducto;
    v_dp.cantidad := 1;
    v_dp.preciounidad := v_precio_producto;
    v_dp.numerolinea := v_numerolinea;
    
    insert into detallepedidos values v_dp;
    
    
end;
/

create sequence s_nueva_unidad_producto start with 132;
/

declare
    v_idpedido number;
begin
    ONE_CLICK_BUY(1,'AR-001',v_idpedido);
end;
/