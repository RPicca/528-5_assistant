import win32com.client
import subprocess
# import numpy as np
import math
# Pour utiliser cette macro : Placer le site Target à l'emplacement à étudier et sélectionner l'émetteur (XG) à étudier
# Régler la valeur du time percentage
# Lancer la macro => on obtient la valeur du pathloss

time_percent = 99
exe_path = "\\\\sisyphe\\TestsStorage\\Tests_Addins\\Products\ITU528-5\\Executables\\P528Drvr_x86.exe"


def AtollMacro_528_point_analysis():
    doc = win32com.client.dynamic.Dispatch(Atoll.ActiveDocument)
    site_table = win32com.client.dynamic.Dispatch(doc.GetRecords("Sites", False))
    target_row = site_table.FindPrimaryKey("Target")
    tx = doc.Selection
    tx_table = win32com.client.dynamic.Dispatch(doc.GetRecords("XGTransmitters", True))
    if tx == None or target_row == -1:
        print("Selectionner un émetteur et positionner le site Target avant de lancer la macro")
    else:
        tx_row = tx_table.FindPrimaryKey(tx.Name)
        if tx_row == -1:
            print("Sélectionner un émetteur XG")
        else:
            # On récup les infos sur le tx
            [tx_site, tx_X, tx_Y, antenna_height, fband] = tx_table.GetValues(
                [tx_row], ["SITE_NAME", "ABS_X", "ABS_Y", "HEIGHT", "FBAND"])[1][1:6]
            # On récup les infos du site du tx
            tx_site_row = site_table.FindPrimaryKey(tx_site)
            # altitude récupérée en formattée sinon égale à None
            tx_site_height = int(site_table.GetFormattedValue(
                tx_site_row, "ALTITUDE").replace("[", "").replace("]", ""))
            tx_total_height = tx_site_height + antenna_height
            # On récup la fréquence centrale de l'émetteur
            f_table = win32com.client.dynamic.Dispatch(doc.GetRecords("xgfreqbands", True))
            f_row = f_table.FindPrimaryKey(fband)
            freq = f_table.GetValue(f_row, "REF_FREQUENCY")
            # On récup les infos sur l'emplacement du site Target
            [target_X, target_Y] = site_table.GetValues([target_row], ["LONGITUDE", "LATITUDE"])[1][1:3]

            rx_table = win32com.client.dynamic.Dispatch(doc.GetRecords("receivers", True))
            rx_row = rx_table.FindPrimaryKey("LTE")
            rx_height = rx_table.GetValue(rx_row, "HEIGHT")

            distance = distance_grand_cercle([tx_X, tx_Y, tx_total_height], [target_X, target_Y, rx_height])
            print(f"Distance : {distance}")
            # Execute le programme d'ITU avec les bons arguments
            options = ["-mode", "POINT", "-h1", str(tx_total_height), "-h2", str(rx_height),
                       "-f", str(freq), "-p", str(time_percent), "-tpol", "1", "-d", str(distance / 1000)]
            result = subprocess.run([exe_path] + options, check=True, capture_output=True, text=True)
            print(result.stdout.split("\n")[1])


def distance_grand_cercle(Tx, Rx):
    a0 = 6371000
    # Distance au sol entre Tx et Rx
    dist = math.dist(Tx[:2], Rx[:2])
    # Pythagore sur le triangle isocele depuis le centre de la terre vers le Tx et le Rx
    triangle_height_length = math.sqrt(a0**2 - (dist / 2)**2)
    tan_phi = dist / 2 / triangle_height_length
    return math.atan(tan_phi) * 2 * a0
