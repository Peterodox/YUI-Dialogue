# Determine if an item <Right Click to Open> before the item is pushed into the bags BAG_UPDATE
# ItemSparse https://wago.tools/db2/ItemSparse?filter[Flags_2]=0x20000&page=1
# Flags_0: 0x4 (Has Loot Table) including items that open the Loot Window
# Flags_2: 0x20000 (Push Loot)

import csv

dataSourcePath = 'G:\\Peter\\NarciUI TWW\\Resources\\'
outPutPath = 'G:\\Peter\\NarciUI TWW\\Python\\'

itemData = open(dataSourcePath +'ItemSparse.11.1.7.60520.csv')
r_itemData = csv.reader(itemData)
newLuaFile = open(outPutPath +'ContainerItem.lua', 'w', newline='')
f_LuaFile = csv.writer(newLuaFile)
f_LuaFile.writerow( ['ContainerItem = {'] )

isFirstRow = True
targetCol = -1
numItem = 0

for row in r_itemData:
    if isFirstRow:
        isFirstRow = False
        for v in row:
            targetCol = targetCol + 1
            if v == 'Flags_0':
                print(targetCol)
                break
    else:
        v = int(row[targetCol])
        if v & 0x4 == 0x4:
            numItem = numItem + 1
            itemID = row[0]
            f_LuaFile.writerow( [ '[' + itemID + '] = ' + 'true', None ] )

print(numItem)
f_LuaFile.writerow(['}'])