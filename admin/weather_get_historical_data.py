# This code reaches out to get historical weather data for a given station. Mainly using to see if 
# can backfill HDD from some surrounding stations since there's a big gap in my data from when the
# wunderground API shut down. Reverse engineered this API call from
# https://www.weather.gov/wrh/Climate?wfo=gyx

from requests import Session
from datetime import datetime, timedelta
from time import sleep
import os

stations = {
    'Bath': "170409 2",
    'Durham': "172048 2"
}

# header = {}
s = Session()
# s.headers.update(header)

dates = []
today = datetime.now()
start_date = datetime(1992, 1, 1)
while start_date < today:
    dates.append(start_date)
    start_date = start_date.replace(year=start_date.year + (start_date.month // 12), month=((start_date.month % 12) + 1))

url = "https://data.rcc-acis.org/StnData"
csv_header = 'station_id,date,temp_max,temp_min,temp_avg,temp_departure,hdd,cdd,precip,snow_new,snow_depth\n'
for station_name, station_id in stations.items():
    for d in dates:
        start_date = d.strftime("%Y-%m-%d")
        end_date = (d.replace(year=d.year + (d.month // 12), month=((d.month % 12) + 1)) - timedelta(days=1)).strftime("%Y-%m-%d")
        print(station_name, start_date)
        outfile = f'{station_name}_{start_date}_data.csv'
        if os.path.isfile(outfile):
            print(f'{outfile} already exists, skipping...')
            continue
        params = {"elems":[{"name":"maxt","add":"t"},{"name":"mint","add":"t"},{"name":"avgt","add":"t"},{"name":"avgt","normal":"departure91","add":"t"},{"name":"hdd","add":"t"},{"name":"cdd","add":"t"},{"name":"pcpn","add":"t"},{"name":"snow","add":"t"},{"name":"snwd","add":"t"}],"sid":station_id,"sDate":start_date,"eDate":end_date}
        try:
            response = s.post(url, json=params)
        except:
            continue
        if response.status_code == 200:
            data = response.json()['data']
            with open(outfile, 'w') as csvfile:
                csvfile.write(csv_header)
                for row in data:
                    csvfile.write(station_id + ',' + ','.join([row[0]] + [i[0] for i in row[1:]]) + '\n')
        sleep(10)
