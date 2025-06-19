#!/usr/bin/env python3

import rasterio
import numpy as np
import argparse # Para argumentos de línea de comandos

def crear_tif_rgb(ruta_banda_roja, ruta_banda_verde, ruta_banda_azul, ruta_salida_rgb):
    """
    Combina tres imágenes TIFF de una sola banda en una única imagen TIFF de 3 bandas (RGB).

    Args:
        ruta_banda_roja (str): Ruta al archivo TIFF para la banda roja.
        ruta_banda_verde (str): Ruta al archivo TIFF para la banda verde.
        ruta_banda_azul (str): Ruta al archivo TIFF para la banda azul.
        ruta_salida_rgb (str): Ruta donde se guardará la imagen TIFF RGB de salida.
    """
    try:
        # Abrir los archivos de cada banda individual
        with rasterio.open(ruta_banda_roja) as src_r, \
             rasterio.open(ruta_banda_verde) as src_g, \
             rasterio.open(ruta_banda_azul) as src_b:

            # Leer los datos de cada banda (asumiendo que son archivos de una sola banda)
            rojo = src_r.read(1)
            verde = src_g.read(1)
            azul = src_b.read(1)

            # Verificar si las dimensiones coinciden
            if not (rojo.shape == verde.shape == azul.shape):
                print(f"Error: Las bandas de entrada no tienen las mismas dimensiones.")
                print(f"Dimensiones banda roja: {rojo.shape}")
                print(f"Dimensiones banda verde: {verde.shape}")
                print(f"Dimensiones banda azul: {azul.shape}")
                return

            # Obtener metadatos de uno de los archivos de origen (ej. banda roja)
            # Este perfil se usará como plantilla para el archivo de salida.
            perfil = src_r.profile

            # Actualizar el perfil para la imagen RGB de salida
            perfil.update(
                count=3,             # Número de bandas
                photometric='RGB',   # Interpretación fotométrica
                driver='GTiff'       # Asegurar que la salida sea GeoTIFF (normalmente ya está configurado)
            )
            # Si 'nodata' está en el perfil y es diferente por banda, esto necesita un manejo cuidadoso.
            # Por simplicidad, asumimos que nodata es consistente o no crítico aquí.

            # Apilar las bandas en un array numpy 3D (bandas, alto, ancho)
            datos_rgb = np.array([rojo, verde, azul])

            # Escribir el archivo TIF RGB de salida
            with rasterio.open(ruta_salida_rgb, 'w', **perfil) as dst:
                dst.write(datos_rgb) # Escribe todas las bandas a la vez

            print(f"Éxito: Imagen TIF RGB creada en '{ruta_salida_rgb}'")

    except FileNotFoundError as e:
        print(f"Error: Archivo no encontrado - {e.filename}")
    except rasterio.RasterioIOError as e:
        print(f"Error: Error de E/S de Rasterio - {e}")
    except Exception as e:
        print(f"Ocurrió un error inesperado: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Combina tres TIFFs de una banda en un TIFF RGB de tres bandas.",
        formatter_class=argparse.RawTextHelpFormatter # Para un mejor formato de la ayuda
    )
    parser.add_argument("banda_roja", help="Ruta al archivo TIFF de la banda roja.")
    parser.add_argument("banda_verde", help="Ruta al archivo TIFF de la banda verde.")
    parser.add_argument("banda_azul", help="Ruta al archivo TIFF de la banda azul.")
    parser.add_argument("salida_rgb", help="Ruta para el archivo TIFF RGB de salida.")
    
    parser.add_argument(
        "--example",
        action="store_true",
        help="Muestra un ejemplo de cómo ejecutar el script y sale."
    )

    args = parser.parse_args()

    if args.example:
        print("\nEjemplo de uso:")
        print("  python nombre_del_script.py ruta/a/banda_roja.tif ruta/a/banda_verde.tif ruta/a/banda_azul.tif ruta/a/salida_rgb.tif")
        print("\nPor ejemplo:")
        print("  python script_combinar_bandas.py C:/imagenes/sensorX_banda4.tif C:/imagenes/sensorX_banda3.tif C:/imagenes/sensorX_banda2.tif C:/imagenes_procesadas/imagen_rgb_final.tif")
        exit(0)

    crear_tif_rgb(args.banda_roja, args.banda_verde, args.banda_azul, args.salida_rgb)

    # --- Alternativa: Modificar rutas directamente en el script (menos flexible) ---
    # Si prefieres no usar argumentos de línea de comandos, puedes comentar
    # las líneas de `argparse` y `crear_tif_rgb` de arriba, y descomentar
    # y modificar las siguientes líneas:

    # print("Modo de rutas directas activado. Edita las rutas en el script.")
    # ruta_roja_ejemplo = 'ruta/a/tu/banda_roja.tif'
    # ruta_verde_ejemplo = 'ruta/a/tu/banda_verde.tif'
    # ruta_azul_ejemplo = 'ruta/a/tu/banda_azul.tif'
    # ruta_salida_ejemplo = 'ruta/a/tu/imagen_rgb_salida.tif'
    #
    # # Comprueba si las rutas de ejemplo han sido modificadas
    # if ruta_roja_ejemplo == 'ruta/a/tu/banda_roja.tif':
    # print("\nPor favor, actualiza las rutas de los archivos TIFF directamente en el script" \
    # " dentro del bloque if __name__ == \"__main__\":")
    # else:
    # crear_tif_rgb(ruta_roja_ejemplo, ruta_verde_ejemplo, ruta_azul_ejemplo, ruta_salida_ejemplo)
