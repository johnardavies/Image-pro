#Source of coordinates
df = pd.read_csv('filepath\\Computers and places\\Londonrnd.csv')

#Location output get's saved to
myloc = r"filepath\Computers and places\London random" #replace with your own location


#Makes a Streetview API request
def GetStreet(Add,SaveLoc):
  base = "https://maps.googleapis.com/maps/api/streetview?size=1200x800&location="
  MyUrl = base + Add +'&key=xxxxx' 
  print(MyUrl)
  fi = Add + ".jpg"
  urllib.request.urlretrieve(MyUrl, os.path.join(SaveLoc,fi))

    
#Loops through the coordinates and calls the API repeatedly
for index, row in df.iterrows():
   time.sleep(5)
   budloc=str(row[['lat','lon']][0])+','+str(row[['lat','lon']][1])
   print(budloc)
   GetStreet(budloc, myloc)