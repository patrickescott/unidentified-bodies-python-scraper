from bs4 import BeautifulSoup
from urllib2 import urlopen
import csv
import time

# function to parse web page
def make_soup(url):
	html = urlopen(url).read()
	return BeautifulSoup(html,"lxml")

if __name__ == '__main__':

	links = []

	# gets all links to missing person profiles
	for i in range(1,21,1):
		url_to_scrape = "http://missingpersons.police.uk/en/search/" + str(i)
		soup = make_soup(url_to_scrape)
		bodies = soup.findAll("li", "Highlight")
		for body in bodies:
			links.append("http://missingpersons.police.uk" + body.a["href"])
		time.sleep(1)

	# gets details from each link and writes to csv
	with open("bodies.csv", 'w') as outfile:
		new_file = csv.writer(outfile)
		new_file.writerow(["id", "status", "source", "gender", "age", "ethnicity", "height", "build", "date", "circumstances"])
		
		id_no = 0

		for link in links: 
			id_no += 1
			
			try:
				soup = make_soup(link)
				time.sleep(1)
				cells = soup.findAll("td")
				gender = cells[1].string
				age = cells[3].string
				ethnicity = cells[5].string
				height = cells[7].string
				build = cells[9].string
				date = cells[11].string
				circumstances = soup.find('p').string
				new_file.writerow([id_no, "ok", link, gender, age, ethnicity, height, build, date, circumstances])
				
			except:
				new_file.writerow([id_no, "failed", link])

		
	if not outfile.closed:
		outfile.close()
