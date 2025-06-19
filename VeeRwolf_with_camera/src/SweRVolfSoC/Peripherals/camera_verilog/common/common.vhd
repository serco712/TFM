---------------------------------------------------------------------
--
--  Fichero:
--    common.vhd  07/09/2023
--
--    (c) J.M. Mendias
--    Dise�o Autom�tico de Sistemas
--    Facultad de Inform�tica. Universidad Complutense de Madrid
--
--  Prop�sito:
--    Contiene definiciones de constantes, funciones de utilidad
--    y componentes reusables
--
--  Notas de dise�o:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is

  constant YES  : std_logic := '1';
  constant NO   : std_logic := '0';
  constant HI   : std_logic := '1';
  constant LO   : std_logic := '0';
  constant ONE  : std_logic := '1';
  constant ZERO : std_logic := '0';
  
  -- Calcula el logaritmo en base-2 de un numero.
  function log2(v : in natural) return natural;
  -- Selecciona un entero entre dos.
  function int_select(s : in boolean; a : in integer; b : in integer) return integer;
  -- Convierte un caracter en un std_logic_vector(7 downto 0). 
  function char2slv(c: character) return std_logic_vector; 
  -- Calcula el numero de ciclos de reloj a una frecuencia (en KHz) que equivalen a un tiempo absoluto (en ns) dado. 
  function ns2cycles(fkHz : in natural; tns: in natural) return natural;
  -- Calcula el numero de ciclos de reloj a una frecuencia (en KHz) que equivalen a un tiempo absoluto (en us) dado. 
  function us2cycles(fkHz : in natural; tus: in natural) return natural;
  -- Calcula el numero de ciclos de reloj a una frecuencia (en KHz) que equivalen a un tiempo absoluto (en ms) dado. 
  function ms2cycles(fKHz : in natural; tms: in natural) return natural;
  -- Calcula el numero de ciclos de reloj a una frecuencia (en KHz) que equivalen a un ciclo de otra frecuencia (en Hz) dado. 
  function hz2cycles(fKHz : in natural; fHz: in natural) return natural;
  -- Convierte un real en un signed en punto fijo con qn bits enteros y qm bits decimales. 
  function toFix( d: real; qn : natural; qm : natural ) return signed; 
  
  -- Convierte codigo binario a codigo 7-segmentos
  component bin2segs
    port
    (
      -- host side
      en     : in std_logic;                      -- capacitacion
      bin    : in std_logic_vector(3 downto 0);   -- codigo binario
      dp     : in std_logic;                      -- punto
      -- leds side
      segs_n : out std_logic_vector(7 downto 0)   -- codigo 7-segmentos
    );
  end component;
  
  --Elimina los vaivenes transitorios de la señal
  component debouncer
      generic(
        FREQ_KHZ  : natural;    -- frecuencia de operacion en KHz
        BOUNCE_MS : natural;    -- tiempo de rebote en ms
        XPOL      : std_logic   -- polaridad (valor en reposo) de la se�al a la que eliminar rebotes
      );
      port (
        clk  : in  std_logic;   -- reloj del sistema
        rst  : in  std_logic;   -- reset s�ncrono del sistema
        x    : in  std_logic;   -- entrada binaria a la que deben eliminarse los rebotes
        xDeb : out std_logic    -- salida que sique a la entrada pero sin rebotes
      );
  end component;
  
  --Convierte una señal que se activa durante varios ciclos en una que lo hace durante un solo ciclo
  component edgeDetector
      generic(
        XPOL  : std_logic         -- polaridad (valor en reposo) de la se�al a la que eliminar rebotes
      );
      port (
        clk   : in  std_logic;   -- reloj del sistema
        x     : in  std_logic;   -- entrada binaria con flancos a detectar
        xFall : out std_logic;   -- se activa durante 1 ciclo cada vez que detecta un flanco de subida en x
        xRise : out std_logic    -- se activa durante 1 ciclo cada vez que detecta un flanco de bajada en x
      );
  end component;
  
  --Hace que la señal cambie en instantes síncronos
  component synchronizer
      generic (
        STAGES  : natural;       -- n�mero de biestables del sincronizador
        XPOL    : std_logic      -- polaridad (valor en reposo) de la se�al a sincronizar
      );
      port (
        clk   : in  std_logic;   -- reloj del sistema
        x     : in  std_logic;   -- entrada binaria a sincronizar
        xSync : out std_logic    -- salida sincronizada que sigue a la entrada
      );
  end component;
  
  component freqSynthesizer
      generic (
        FREQ_KHZ : natural;                 -- frecuencia del reloj de entrada en KHz
        MULTIPLY : natural range 1 to 64;   -- factor por el que multiplicar la frecuencia de entrada 
        DIVIDE   : natural range 1 to 128   -- divisor por el que dividir la frecuencia de entrada
      );
      port (
        clkIn  : in  std_logic;   -- reloj de entrada
        ready  : out std_logic;   -- indica si el reloj de salida es v�lido
        clkOut : out std_logic    -- reloj de salida
      );
  end component;
  
  
  component asyncRstSynchronizer
      generic (
        STAGES : natural;         -- n�mero de biestables del sincronizador
        XPOL   : std_logic        -- polaridad (en reposo) de la se�al de reset
      );
      port (
        clk    : in  std_logic;   -- reloj del sistema
        rstIn  : in  std_logic;   -- rst de entrada
        rstOut : out std_logic    -- rst de salida
      );
  end component;
  
  component segsBankRefresher
      generic(
        FREQ_KHZ : natural;   -- frecuencia de operacion en KHz
        SIZE     : natural    -- n�mero de displays a refrescar     
      );
      port (
        -- host side
        clk    : in std_logic;                              -- reloj del sistema
        ens    : in std_logic_vector (SIZE-1 downto 0);     -- capacitaciones
        bins   : in std_logic_vector (4*SIZE-1 downto 0);   -- c�digos binarios a mostrar
        dps    : in std_logic_vector (SIZE-1 downto 0);     -- puntos
        -- 7 segs display side
        an_n   : out std_logic_vector (SIZE-1 downto 0);    -- selector de display  
        segs_n : out std_logic_vector (7 downto 0)          -- c�digo 7 segmentos 
      );
  end component;
 
 component ps2receiver 
    port (
        -- host side
        clk        : in  std_logic;   -- reloj del sistema
        rst        : in  std_logic;   -- reset s�ncrono del sistema      
        dataRdy    : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
        data       : out std_logic_vector (7 downto 0);  -- dato recibido
        -- PS2 side
        ps2Clk     : in  std_logic;   -- entrada de reloj del interfaz PS2
        ps2Data    : in  std_logic    -- entrada de datos serie del interfaz PS2
      );
 end component;
 
 
 component rs232receiver
      generic (
        FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
        BAUDRATE : natural   -- velocidad de comunicacion
      );
      port (
        -- host side
        clk     : in  std_logic;   -- reloj del sistema
        rst     : in  std_logic;   -- reset s�ncrono del sistema
        dataRdy : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
        data    : out std_logic_vector (7 downto 0);   -- dato recibido
        -- RS232 side
        RxD     : in  std_logic    -- entrada de datos serie del interfaz RS-232
      );
 end component;
 
 
 component rs232transmitter
      generic (
        FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
        BAUDRATE : natural   -- velocidad de comunicacion
      );
      port (
        -- host side
        clk     : in  std_logic;   -- reloj del sistema
        rst     : in  std_logic;   -- reset s�ncrono del sistema
        dataRdy : in  std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato a transmitir
        data    : in  std_logic_vector (7 downto 0);   -- dato a transmitir
        busy    : out std_logic;   -- se activa mientras esta transmitiendo
        -- RS232 side
        TxD     : out std_logic    -- salida de datos serie del interfaz RS-232
      );
 end component;
 
 component fifoQueue
      generic (
        WL    : natural;   -- anchura de la palabra de fifo
        DEPTH : natural    -- numero de palabras en fifo
      );
      port (
        clk     : in  std_logic;   -- reloj del sistema
        rst     : in  std_logic;   -- reset s�ncrono del sistema
        wrE     : in  std_logic;   -- se activa durante 1 ciclo para escribir un dato en la fifo
        dataIn  : in  std_logic_vector(WL-1 downto 0);   -- dato a escribir
        rdE     : in  std_logic;   -- se activa durante 1 ciclo para leer un dato de la fifo
        dataOut : out std_logic_vector(WL-1 downto 0);   -- dato a leer
        numData : out std_logic_vector(log2(DEPTH)-1 downto 0);   -- numero de datos almacenados
        full    : out std_logic;   -- indicador de fifo llena
        empty   : out std_logic    -- indicador de fifo vacia
      );
 end component;
    
 component vgaRefresher
      generic(
        FREQ_DIV  : natural  -- razon entre la frecuencia de reloj del sistema y 25 MHz
      );
      port ( 
        -- host side
        clk   : in  std_logic;   -- reloj del sistema
        line  : out std_logic_vector(9 downto 0);   -- numero de linea que se esta barriendo
        pixel : out std_logic_vector(9 downto 0);   -- numero de pixel que se esta barriendo
        R     : in  std_logic_vector(3 downto 0);   -- intensidad roja del pixel que se esta barriendo
        G     : in  std_logic_vector(3 downto 0);   -- intensidad verde del pixel que se esta barriendo
        B     : in  std_logic_vector(3 downto 0);   -- intensidad azul del pixel que se esta barriendo
        -- VGA side
        hSync : out std_logic := '0';   -- sincronizacion horizontal
        vSync : out std_logic := '0';   -- sincronizacion vertical
        RGB   : out std_logic_vector(11 downto 0) := (others => '0')   -- canales de color
      );
 end component;
    
 component vgaTextInterface
      generic(
        FREQ_DIV : natural;  -- valor por el que dividir la frecuencia del reloj del sistema para obtener 25 MHz
        BGCOLOR  : std_logic_vector (11 downto 0); -- color del background
        FGCOLOR  : std_logic_vector (11 downto 0)  -- color del foreground
      );
      port ( 
        -- host side
        clk     : in std_logic;   -- reloj del sistema
        clear   : in std_logic;   -- borra la memoria de refresco
        dataRdy : in std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo caracter a visualizar
        char    : in std_logic_vector (7 downto 0);   -- codigo ASCII del caracter a visualizar
        x       : in std_logic_vector (6 downto 0);   -- columna en donde visualizar el caracter
        y       : in std_logic_vector (4 downto 0);   -- fila en donde visualizar el caracter
        --
        col     : out std_logic_vector (6 downto 0);   -- numero de columna que se esta barriendo
        uCol    : out std_logic_vector (2 downto 0);   -- numero de microcolumna que se esta barriendo
        row     : out std_logic_vector (4 downto 0);   -- numero de fila que se esta barriendo
        uRow    : out std_logic_vector (3 downto 0);   -- numero de microfila que se esta barriendo
        -- VGA side
        hSync  : out std_logic;   -- sincronizacion horizontal
        vSync  : out std_logic;   -- sincronizacion vertical
        RGB    : out std_logic_vector (11 downto 0)   -- canales de color
      );
 end component;
 
 component iisInterface
  generic (
    WL         : natural;  -- anchura de las muestras
    FREQ_DIV    : natural;  -- razon entre la frecuencia de reloj del sistema y 25 MHz
    UNDERSAMPLE : natural   -- factor de submuestreo 
  );
  port ( 
    -- host side
    clk       : in  std_logic;   -- reloj del sistema
    rChannel  : out std_logic;   -- en alta cuando la muestra corresponde al canal derecho; a baja cuando es el izquierdo
    newSample : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido o que enviar
    inSample  : out std_logic_vector(WL-1 downto 0);  -- muestra recibida del AudioCodec
    outSample : in  std_logic_vector(WL-1 downto 0);  -- muestra a enviar al AudioCodec
    -- IIS side
    mclk      : out std_logic;   -- master clock, 256fs
    sclk      : out std_logic;   -- serial bit clocl, 64fs
    lrck      : out std_logic;   -- left-right clock, fs
    sdti      : out std_logic;   -- datos serie hacia DACs
    sdto      : in  std_logic    -- datos serie desde ADCs
  );
 end component;

 component vgaGraphicInterface
  generic(
    FREQ_DIV : natural  -- valor por el que dividir la frecuencia del reloj del sistema para obtener 25 MHz
  );
  port ( 
    -- host side
    clk     : in std_logic;   -- reloj del sistema
    clear   : in std_logic;   -- borra la memoria de refresco
    dataRdy : in std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo pixel a visualizar
    color   : in std_logic_vector (2 downto 0);   -- color del pixel a visualizar
    x       : in std_logic_vector (9 downto 0);   -- columna en donde visualizar el pixel
    y       : in std_logic_vector (8 downto 0);   -- fila en donde visualizar el pixel
    --
    line    : out std_logic_vector(8 downto 0);   -- numero de linea que se esta barriendo
    pixel   : out std_logic_vector(9 downto 0);   -- numero de pixel que se esta barriendo
    -- VGA side
    hSync   : out std_logic;   -- sincronizacion horizontal
    vSync   : out std_logic;   -- sincronizacion vertical
    RGB     : out std_logic_vector (11 downto 0)   -- canales de color
  );
 end component;

 component ps2interface
  generic(
    FREQ_KHZ  : natural    -- frecuencia de operacion en KHz
  );
  port (
    -- host side
    clk        : in  std_logic;   -- reloj del sistema
    rst        : in  std_logic;   -- reset s�ncrono del sistema      
    RxDataRdy  : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
    RxData     : out std_logic_vector (7 downto 0);   -- dato recibido
    TxDataRdy  : in  std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato a transmitir   
    TxData     : in  std_logic_vector (7 downto 0);   -- dato a transmitir
    busy       : out std_logic;   -- se activa mientras esta transmitiendo
    -- PS2 side
    ps2Clk     : inout  std_logic;   -- reloj del interfaz PS2
    ps2Data    : inout  std_logic    -- datos serie del interfaz PS2
  );
 end component;
 
 component ov7670programmer
  generic (
    FREQ_KHZ : natural;                        -- frecuencia de operacion en KHz
    BAUDRATE : natural;                        -- velocidad de comunicacion
    DEV_ID   : std_logic_vector (6 downto 0)   -- direcci�n SCCB (7 bits) de la camara
  );
  port ( 
    -- host side
    clk  : in  std_logic;         -- reloj del sistema
    rdy  : out std_logic;         -- indica si la programaci�n ha finalizado
    -- SSCB side
    sioc : out std_logic;  -- reloj serie
    siod : out std_logic   -- datos serie
  );
 end component;
 
 component ov7670reader
  port ( 
    -- host side
    clk      : in  std_logic;  -- reloj del sistema    
    rec      : in  std_logic;  -- captura video mientras esta activa
    -- frame buffer side
    y        : out std_logic_vector (8 downto 0);    -- coordenada vertical del pixel (0: arriba)
    x        : out std_logic_vector (9 downto 0);    -- coordenada horizontal del pixel (0: izquierda)
    dataRdy  : out std_logic;                        -- se activa durante 1 ciclo cada vez que ha recibido un nuevo pixel
    data     : out std_logic_vector (11 downto 0);   -- color del pixel recibido
    frameRdy : out std_logic;                        -- se activa durante 1 ciclo cada vez que ha recibido una nueva frame
    -- ov7670 video side
    pclk     : in  std_logic;                        -- reloj de pixel
    cvSync   : in  std_logic;                        -- sincronizacion vertical
    href     : in  std_logic;                        -- se activa durante la transmisi�n de un frame horizontal
    cData    : in  std_logic_vector (7 downto 0)     -- muestra recibida del sensor de imagen   
  );
 end component;
 
 component rgb2grey
  port (
    -- camera side
    rgb  : in std_logic_vector(11 downto 0);   -- color
    -- screen side
    grey : out std_logic_vector(3 downto 0)    -- gris
  );
 end component;
 
 component lsfr
      generic(
        WL : natural   -- anchura del numero aleatorio
      );
      port(
        clk    : in  std_logic;   -- reloj del sistema
        rst    : in  std_logic;   -- reset s�ncrono del sistema
        ce     : in  std_logic;   -- activa la generacion de numeros aleatorios (1 por ciclo de reloj)
        ld     : in  std_logic;   -- carga la semilla
        seed   : in  std_logic_vector(WL-1 downto 0);   -- semilla
        random : out std_logic_vector(WL-1 downto 0)    -- numero aleatorio
       );
 end component;

end package common;

-------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;

package body common is

  function log2(v : in natural) return natural is
    variable n    : natural;
    variable logn : natural;
  begin
    n := 1;
    for i in 0 to 128 loop
      logn := i;
      exit when (n >= v);
      n := n * 2;
    end loop;
    return logn;
  end function log2;
  
  function int_select(s : in boolean; a : in integer; b : in integer) return integer is
  begin
    if s then
      return a;
    else
      return b;
    end if;
    return a;
  end function int_select;
    
  function char2slv(c: character) return std_logic_vector is 
  begin 
    return std_logic_vector(to_unsigned(natural(character'pos(c)),8)); 
  end function;    
  
  function ns2cycles(fKHz : in natural; tns: in natural) return natural is
    constant NORM_NSxKHZ : natural := 1_000_000;  -- Factor de normalizaci�n ns * KHz
  begin
    return (tns*fKHz)/NORM_NSxKHZ;  
  end function;
  
  function us2cycles(fKHz : in natural; tus: in natural) return natural is
    constant NORM_USxKHZ : natural := 1_000;  -- Factor de normalizaci�n us * KHz
  begin
    return tus*(fKHz/NORM_USxKHZ);  
  end function;
  
  function ms2cycles(fKHz : in natural; tms: in natural) return natural is
  begin
    return tms*fKHz;  
  end function;
  
  function hz2cycles(fKHz : in natural; fHz: in natural) return natural is
  begin
    return fKHz*1000/fHz;
  end function;

  function toFix( d: real; qn : natural; qm : natural ) return signed is 
  begin 
    return to_signed( integer(d*(2.0**qm)), qn+qm );
  end function; 
  
end package body common;
