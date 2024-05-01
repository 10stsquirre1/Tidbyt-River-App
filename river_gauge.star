#River level display for Tidbyt by @KaySavetz
#Find your local gauge at https://water.weather.gov/ahps/

load("render.star", "render")
load("re.star", "re")
load("http.star", "http")
load("cache.star", "cache")
load("time.star", "time")

TTL = 600

def main(config):
    gauge = config.get("gauge") or 'seli2' #replace prto3 with your chosen gauge

    obcolor = "#4DD" 
    hicolor = "#4CC" 

    today = time.now()
    today = today.format("Jan _2, 2006")
    print(today)

    tomorrow = time.now() + time.parse_duration("24h")
    tomorrow = tomorrow.format("Jan _2, 2006")

    data = cache.get(gauge)
    if data != None:
      print("Displaying cached data for " + gauge)
    else:
      print("Fetching fresh river data for " + gauge)
      resp = http.get("https://water.weather.gov/ahps2/rss/alert/" + gauge + ".rss")
      if resp.status_code != 200:
        fail("Request failed with status %d", resp.status_code)

      data = resp.body()
      cache.set(gauge, data, ttl_seconds=TTL)

    element = re.match('Latest Observation (Secondary): ([0-9]*.?[0-9]*) kcfs', data)
    if element:
        kcfs = element[0][1]
        print("Pumping at " + str(kcfs) + " kcfs")
    else:
        print("No latest observation")
        kcfs = "???"

    element = re.match('Latest Observation: ([0-9]*.?[0-9]*) ft', data)
    if element:
        feet = element[0][1]
        print("We're at " + str(feet) + " feet")
    else:
        print("No latest observation")
        feet = "???"

    element = re.match('Latest Observation Category: (.*?)&', data)
    if element:
        category = element[0][1]
        print("Category is " + category)
        if category == "Normal":   #only show category if at alert level
            category = "                "  #hack to center text on display under normal conditions
        else:
            if category != "Low Water" and category != "Not defined":
                obcolor = "#C00"  #red for any non-normal category except Low Water and Not defined
    else:
        print("No category")
        category = "                "

