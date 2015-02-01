import cherrypy, subprocess, psutil, os, json, datetime
from jinja2 import Environment, FileSystemLoader
env = Environment(loader=FileSystemLoader('/opt/homepage'))

class Root:
    @cherrypy.expose
    def index(self):

        bandwidth = getBandwidth()

        transmission, couchpotato, sickbeard, headphones = get_program_status()

        tmpl = env.get_template('index.html')
        return tmpl.render(
            # sys info
            cpu        = psutil.cpu_percent(),
            ram        = psutil.virtual_memory().percent,
            bootTime   = psutil.get_boot_time(),
            usedDisk   = convertBytes(psutil.disk_usage('/').used),
            totalDisk  = psutil.disk_usage('/').total >> 30,
            monthlyBW  = {{MONTHLY_BANDWIDTH}},
            currTime   = str(datetime.datetime.now()),
            # Charts
            hourly_tx  = bandwidth['hourly_tx'],
            hourly_rx  = bandwidth['hourly_rx'],
            daily_tx   = bandwidth['daily_tx'],
            daily_rx   = bandwidth['daily_rx'],
            monthly_tx = bandwidth['monthly_tx'],
            monthly_rx = bandwidth['monthly_rx'],
            totalAll   = bandwidth['totalAll'],
            totalMonth = bandwidth['totalMonth'],
            # Maintenance
            transmissionIsOn = transmission,
            couchpotatoIsOn  = couchpotato,
            sickbeardIsOn    = sickbeard,
            headphonesIsOn   = headphones,
            # Streaming Media
            tv     = get_directory_structure('/home/tv'),
            music  = get_directory_structure('/home/music'),
            other  = get_directory_structure('/home/other'),
            movies = get_directory_structure('/home/movies')
        )


# Maintenance API
class Maintenance:
    @cherrypy.expose
    def transmission_on(self):
        transmission, _, _, _ = get_program_status()
        if not transmission:
            subprocess.call(['service', 'transmission-daemon', 'start'])
            transmission = 1
        return json.dumps({'status': transmission})

    @cherrypy.expose
    def transmission_off(self):
        transmission, _, _, _ = get_program_status()
        if transmission:
            subprocess.call(['service', 'transmission-daemon', 'stop'])
            transmission = 0
        return json.dumps({'status': transmission})

    @cherrypy.expose
    def couchpotato_on(self):
        _, couchpotato, _, _ = get_program_status()
        if not couchpotato:
            subprocess.call(['service', 'couchpotato', 'start'])
            couchpotato = 1
        return json.dumps({'status': couchpotato})

    @cherrypy.expose
    def couchpotato_off(self):
        _, couchpotato, _, _ = get_program_status()
        if couchpotato:
            subprocess.call(['service', 'couchpotato', 'stop'])
            couchpotato = 0
        return json.dumps({'status': couchpotato})

    @cherrypy.expose
    def sickbeard_on(self):
        _, _, sickbeard, _ = get_program_status()
        if not sickbeard:
            subprocess.call(['service', 'sickbeard', 'start'])
            sickbeard = 1
        return json.dumps({'status': sickbeard})

    @cherrypy.expose
    def sickbeard_off(self):
        _, _, sickbeard, _ = get_program_status()
        if sickbeard:
            subprocess.call(['service', 'sickbeard', 'stop'])
            sickbeard = 0
        return json.dumps({'status': sickbeard})

    @cherrypy.expose
    def headphones_on(self):
        _, _, _, headphones = get_program_status()
        if not headphones:
            subprocess.call(['service', 'headphones', 'start'])
            headphones = 1
        return json.dumps({'status': headphones})

    @cherrypy.expose
    def headphones_off(self):
        _, _, _, headphones = get_program_status()
        if headphones:
            cmd = ['service', 'headphones', 'stop']
            subprocess.call(cmd)
            headphones = 0
        return json.dumps({'status': headphones})

    @cherrypy.expose
    def generate(self, common_name):
        os.environ["CERTIFICATE_NAME"] = common_name;
        subprocess.call(['/opt/certs/gencert.sh'])
        subprocess.call(['service', 'nginx', 'restart'])
        return

    @cherrypy.expose
    def password(self, username, password):
        os.chdir('/etc/nginx/auth/')
        subprocess.call(['htpasswd', '-b', '-c', '.htpasswd', username, password])
        subprocess.call(['service', 'nginx', 'restart'])
        with open('./js/cred.js', 'w') as f:
            f.write('var cred = ' + json.dumps({
                'username': username,
                'password': password
            }))
        return

    @cherrypy.expose
    def reboot(self, areyousure):
        os.system('reboot')
        return


# MiB -> GiB
def convertMiB(numString):
    return round(float(numString) / 1024, 2)


# KiB -> GiB
def convertKiB(numString):
    return round(float(numString) / 1024 / 1024, 2)


# B -> GiB
def convertBytes(numString):
    return round(float(numString) / 1024 / 1024 / 1024, 1)


def getBandwidth():
    subprocess.call(['vnstat', '-u', '-i', 'venet0'])
    output = subprocess.check_output(['vnstat', '-i', 'venet0', '--dumpdb'])

    hourly_tx  = []
    hourly_rx  = []
    daily_tx   = []
    daily_rx   = []
    monthly_tx = []
    monthly_rx = []
    totalAll   = 0
    totalMonth = 0

    for line in output.splitlines():
        entry = line.split(';')
        # All time bandwidth
        if entry[0] == 'totalrx': totalAll += float(entry[1]);
        if entry[0] == 'totaltx': totalAll += float(entry[1]);
        # By the hour
        if entry[0] == 'h':
            hourly_rx.append(entry[3])
            hourly_tx.append(entry[4])
        # By the day
        if entry[0] == 'd':
            daily_rx.insert(0, entry[3])
            daily_tx.insert(0, entry[4])
        # By the month
        if entry[0] == 'm':
            monthly_rx.insert(0, entry[3])
            monthly_tx.insert(0, entry[4])
            if entry[1] == '0': totalMonth = float(entry[3]) + float(entry[4])

    return {
        'hourly_tx' : map(convertKiB, hourly_tx),
        'hourly_rx' : map(convertKiB, hourly_rx),
        'daily_tx'  : map(convertMiB, daily_tx),
        'daily_rx'  : map(convertMiB, daily_rx),
        'monthly_tx': map(convertMiB, monthly_tx),
        'monthly_rx': map(convertMiB, monthly_rx),
        'totalAll'  : convertMiB(totalAll),
        'totalMonth': convertMiB(totalMonth)
    }


def get_program_status():
    transmission = 0
    couchpotato  = 0
    sickbeard    = 0
    headphones   = 0

    for p in psutil.process_iter():
        if p.name == 'transmission-daemon':
            transmission = 1

    if os.path.isfile('/var/run/couchpotato/couchpotato.pid'):
        couchpotato = 1

    if os.path.isfile('/var/run/sickbeard/sickbeard.pid'):
        sickbeard = 1

    if os.path.isfile('/var/run/headphones/headphones.pid'):
        headphones = 1

    return transmission, couchpotato, sickbeard, headphones


def get_directory_structure(rootdir):
    dir = {}
    _, dirname = os.path.split(rootdir)
    rootdir = rootdir.rstrip(os.sep)
    start = rootdir.rfind(os.sep) + 1
    for path, dirs, files in os.walk(rootdir):
        base = path.replace(rootdir, '')
        folders = path[start:].split(os.sep)
        subdir = dict.fromkeys(files)
        for key in subdir:
            subdir[key] = base + os.sep + key
        parent = reduce(dict.get, folders[:-1], dir)
        parent[folders[-1]] = subdir
    return json.dumps(dir[dirname], indent=2) #, ensure_ascii=False)


root = Root()
root.stream = Root()
root.stream.other = Root()
root.stream.music = Root()
root.stream.movies = Root()
root.stream.tvshows = Root()

root.maintenance = Maintenance()

cherrypy.server.socket_port = 4004

cherrypy.quickstart(root)