from PIL import Image
import math
import os

def hex_string_to_rgb_12bit(hex_str):
    """
    Convierte una cadena hexadecimal donde los 12 bits inferiores representan
    el color (4 bits para Rojo, 4 para Verde, 4 para Azul).
    Ejemplo: 0x...RGB, donde R, G, B son dígitos hexadecimales.
    R = bits 11-8, G = bits 7-4, B = bits 3-0 de la parte relevante.
    Escala los componentes de 4 bits (0-15) a 8 bits (0-255).
    """
    try:
        if hex_str.startswith('0x'):
            hex_str = hex_str[2:]
        
        val = int(hex_str, 16)

        r4 = (val >> 8) & 0x0F
        g4 = (val >> 4) & 0x0F
        b4 = val & 0x0F

        r8 = r4 * 17
        g8 = g4 * 17
        b8 = b4 * 17

        return (r8, g8, b8)
    except ValueError:
        print(f"Advertencia: Valor hexadecimal no válido '{hex_str}' encontrado y omitido.")
        return None
    except Exception as e:
        print(f"Error procesando el valor hexadecimal '{hex_str}': {e}")
        return None

def crear_imagen_desde_archivo_hex_escalado(
    ruta_archivo_hex, 
    ruta_imagen_salida, 
    num_columnas_logicas=640, 
    factor_escala=2
):
    """
    Crea una imagen a partir de un archivo de texto. Cada línea del archivo
    puede contener múltiples valores hexadecimales de color separados por espacios.
    Cada píxel lógico se escala a un bloque de (factor_escala x factor_escala) píxeles.
    Los colores se interpretan como 12 bits (4-4-4 RGB).

    Args:
        ruta_archivo_hex (str): Ruta al archivo de entrada.
        ruta_imagen_salida (str): Ruta donde se guardará la imagen.
        num_columnas_logicas (int): Número de píxeles lógicos por fila antes del escalado.
        factor_escala (int): Factor de escalado para cada píxel lógico.
    """
    colores_rgb = []
    try:
        with open(ruta_archivo_hex, 'r') as f:
            for numero_linea, linea_texto in enumerate(f, 1):
                linea_limpia = linea_texto.strip()
                if not linea_limpia: # Ignorar líneas completamente vacías
                    continue

                valores_hex_en_linea = linea_limpia.split() # Divide por espacios
                
                # Opcional: Verificar si hay exactamente 10 cifras si es un requisito estricto
                # if len(valores_hex_en_linea) != 10:
                #     print(f"Advertencia: La línea {numero_linea} no contiene 10 cifras/números (encontrados: {len(valores_hex_en_linea)}). Se procesarán los encontrados.")

                for hex_val_str in valores_hex_en_linea:
                    if hex_val_str: # Asegurarse de que no sea una cadena vacía
                        rgb = hex_string_to_rgb_12bit(hex_val_str)
                        if rgb:
                            colores_rgb.append(rgb)
    except FileNotFoundError:
        print(f"Error: No se pudo encontrar el archivo de entrada: {ruta_archivo_hex}")
        return
    except Exception as e:
        print(f"Ocurrió un error al leer el archivo: {e}")
        return

    if not colores_rgb:
        print("No se encontraron datos de color válidos en el archivo.")
        return

    num_pixeles_logicos = len(colores_rgb)
    # ... (el resto de la lógica de la función es igual que antes) ...
    if num_pixeles_logicos == 0:
        print("No hay píxeles lógicos para procesar.")
        return
        
    if num_columnas_logicas <= 0:
        print("Error: El número de columnas lógicas debe ser positivo.")
        return
    if factor_escala <= 0:
        print("Error: El factor de escala debe ser positivo.")
        return

    altura_logica = math.ceil(num_pixeles_logicos / num_columnas_logicas)
    
    ancho_final_imagen = num_columnas_logicas * factor_escala
    altura_final_imagen = int(altura_logica * factor_escala)

    if ancho_final_imagen == 0 or altura_final_imagen == 0:
        print("Las dimensiones finales de la imagen serían cero. No se puede crear la imagen.")
        return

    print(f"Se leerán {num_pixeles_logicos} píxeles lógicos en total del archivo.")
    print(f"Columnas lógicas por fila en la imagen: {num_columnas_logicas}")
    print(f"Filas lógicas en la imagen: {int(altura_logica)}")
    print(f"Factor de escala: {factor_escala}x{factor_escala} (cada píxel lógico será un bloque de {factor_escala*factor_escala} píxeles)")
    print(f"Dimensiones de la imagen final: {ancho_final_imagen}x{altura_final_imagen}")

    imagen = Image.new('RGB', (ancho_final_imagen, altura_final_imagen), color='black')
    pixeles_mapa_final = imagen.load()

    for i, color_actual in enumerate(colores_rgb):
        lx = i % num_columnas_logicas
        ly = i // num_columnas_logicas
        start_ax = lx * factor_escala
        start_ay = ly * factor_escala

        for offsetY in range(factor_escala):
            for offsetX in range(factor_escala):
                ax = start_ax + offsetX
                ay = start_ay + offsetY
                if ax < ancho_final_imagen and ay < altura_final_imagen:
                     pixeles_mapa_final[ax, ay] = color_actual
    try:
        imagen.save(ruta_imagen_salida)
        print(f"Imagen guardada exitosamente como '{ruta_imagen_salida}'")
    except Exception as e:
        print(f"Error al guardar la imagen: {e}")

# --- Ejemplo de uso ---
if __name__ == "__main__":
    nombre_archivo_hex = "image.txt"
    
    # datos_prompt = [
    #     "0x00000111", "0x00000111", "0x00000011", "0x00000111",
    #     "0x00000111", "0x00000111", "0x00000111", "0x00000121",
    #     "0x00000111", "0x00000111", "0x00000111", "0x00000111",
    # ]
    # datos_colores_puros_12bit = [
    #     "0xF00", "0x0F0", "0x00F", "0xFF0", "0x0FF", "0xF0F",
    #     "0xFFF", "0x888", "0x000",
    # ] + datos_prompt

    # num_filas_logicas_ejemplo = 3
    #olumnas_logicas_ejemplo = 640 # O el número de columnas lógicas que desees para la imagen
    # num_total_pixeles_logicos_ejemplo = columnas_logicas_ejemplo * num_filas_logicas_ejemplo 
    
    # num_repeticiones = (num_total_pixeles_logicos_ejemplo // len(datos_colores_puros_12bit)) + 1
    # datos_completos_individuales = datos_colores_puros_12bit * num_repeticiones
    # datos_completos_individuales = datos_completos_individuales[:num_total_pixeles_logicos_ejemplo]

    # if not os.path.exists(nombre_archivo_hex):
    #     print(f"Creando archivo de ejemplo '{nombre_archivo_hex}' con {len(datos_completos_individuales)} valores, 10 por línea...")
    #     with open(nombre_archivo_hex, 'w') as f_ejemplo:
    #         for i in range(0, len(datos_completos_individuales), 10):
    #             # Tomar hasta 10 elementos para la línea actual
    #             chunk_de_10 = datos_completos_individuales[i : i + 10]
    #             linea_a_escribir = " ".join(chunk_de_10)
    #             f_ejemplo.write(linea_a_escribir + "\n")
    #     print("Archivo de ejemplo creado.")

    nombre_imagen_salida = "imagen_generada_10_por_linea.png"
    
    crear_imagen_desde_archivo_hex_escalado(
        nombre_archivo_hex, 
        nombre_imagen_salida, 
        num_columnas_logicas=320, # 640 píxeles lógicos por fila en la imagen
        factor_escala=2
    )

    # Prueba rápida con pocos datos:
    # nombre_archivo_test = "colores_test_10_por_linea.txt"
    # datos_test_individuales = ["0x111", "0x222", "0x333", "0x444", "0x555", "0x666", "0x777", "0x888", "0x999", "0xAAA", "0xB00", "0xC00"] # 12 datos
    # with open(nombre_archivo_test, 'w') as f_test:
    #     for i in range(0, len(datos_test_individuales), 10):
    #         chunk = datos_test_individuales[i : i + 10]
    #         f_test.write(" ".join(chunk) + "\n")
    # # La primera línea tendrá 10, la segunda 2.
    # crear_imagen_desde_archivo_hex_escalado(
    #     nombre_archivo_test,
    #     "imagen_test_10_por_linea.png",
    #     num_columnas_logicas=6, # 6 píxeles lógicos por fila en la imagen
    #     factor_escala=2
    # )
    # Esto produciría 12 píxeles lógicos, 2 filas lógicas (6 por fila).
    # Imagen final: (6*2) x (2*2) = 12x4 píxeles.