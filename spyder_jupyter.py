#!/usr/bin/env python

"""
Launch Jupyter Notebook within a Docker notebook image and
automatically open up the URL in the default web browser.
"""

# Author: Xiangmin Jiao <xmjiao@gmail.com>

from __future__ import print_function  # Only Python 2.x

import sys
import subprocess
import time

APP = "spyder"


def parse_args(description):
    "Parse command-line arguments"

    import argparse

    # Process command-line arguments
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument('-u', "--user",
                        help='The username used by the image. ' +
                        ' The default is to retrieve from image.',
                        default="")

    parser.add_argument('-i', '--image',
                        help='The Docker image to use. ' +
                        'The default is compdatasci/' + APP + '-desktop.',
                        default="compdatasci/" + APP + "-desktop")

    parser.add_argument('-t', '--tag',
                        help='Tag of the image. The default is latest. ' +
                        'If the image already has a tag, its tag prevails.',
                        default="latest")

    parser.add_argument('-p', '--pull',
                        help='Pull the latest Docker image. ' +
                        'The default is not to pull.',
                        action='store_true',
                        default=False)

    parser.add_argument('-d', '--detach',
                        help='Run in background and print container id',
                        action='store_true',
                        default=False)

    parser.add_argument('notebook', nargs='?',
                        help='The notebook to open.', default="")

    parser.add_argument('-v', '--volume',
                        help='A data volume to be mounted to ~/project.',
                        default="")

    parser.add_argument('-n', '--no-browser',
                        help='Do not start web browser',
                        action='store_true',
                        default=False)

    args = parser.parse_args()

    # Append tag to image if the image has no tag
    if args.image.find(':') < 0:
        args.image += ':' + args.tag

    return args


def random_ports(port, n):
    """Generate a list of n random ports near the given port.

    The first 5 ports will be sequential, and the remaining n-5 will be
    randomly selected in the range [port-2*n, port+2*n].
    """
    import random

    for i in range(min(5, n)):
        yield port + i
    for i in range(n - 5):
        yield max(1, port + random.randint(-2 * n, 2 * n))


def id_generator(size=6):
    """Generate a container ID"""
    import random
    import string

    chars = string.ascii_lowercase
    return APP + "-" + (''.join(random.choice(chars) for _ in range(size)))


def find_free_port(port, retries):
    "Find a free port"
    import socket

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    for prt in random_ports(port, retries + 1):
        try:
            sock.bind(("127.0.0.1", prt))
            sock.close()
            return prt
        except socket.error:
            continue

    print("Error: Could not find a free port.")
    sys.exit(-1)


def handle_interrupt(container):
    """Handle keyboard interrupt"""
    try:
        print("Press Ctrl-C again to stop the server: ")
        time.sleep(5)
        print('Invalid response. Resuming...')
    except KeyboardInterrupt:
        print('*** Stopping the server.')
        subprocess.Popen(["docker", "exec", container,
                          "killall", "my_init"],
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        sys.exit(0)


if __name__ == "__main__":
    import os
    import webbrowser
    import platform

    args = parse_args(description=__doc__)

    pwd = os.getcwd()
    homedir = os.path.expanduser('~')
    if platform.system() == "Linux":
        if subprocess.check_output(['groups']).find(b'docker') < 0:
            print('You are not a member of the docker group. Please add')
            print('yourself to the docker group using the following command:')
            print('   sudo addgroup $USER docker')
            print('Then, log out and log back in before you can use Docker.')
            sys.exit(-1)
        uid = str(os.getuid())
    else:
        uid = ""

    try:
        img = subprocess.check_output(['docker', 'images', '-q', args.image])
    except:
        print("Docker failed. Please make sure docker was properly " +
              "installed and has been started.")
        sys.exit(-1)

    if args.pull or not img:
        try:
            err = subprocess.call(["docker", "pull", args.image])
        except BaseException:
            err = -1

        if err:
            sys.exit(err)

        # Delete dangling image
        if img and subprocess.check_output(['docker', 'images', '-f',
                                            'dangling=true',
                                            '-q']).find(img) >= 0:
            subprocess.Popen(["docker", "rmi", "-f", img.decode('utf-8')[:-1]])

    # Generate a container ID and find an unused port
    container = id_generator()
    port_http = str(find_free_port(8888, 50))

    # Create directory .ssh if not exist
    if not os.path.exists(homedir + "/.ssh"):
        os.mkdir(homedir + "/.ssh")

    if args.user:
        docker_home = "/home/" + args.user
    else:
        docker_home = subprocess.check_output(["docker", "run", "--rm",
                                               args.image,
                                               "echo $DOCKER_HOME"]). \
            decode('utf-8')[:-1]

    if args.volume and args.clear:
        subprocess.check_output(["docker", "volume", "rm", "-f", args.volume])

    volumes = ["-v", pwd + ":" + docker_home + "/shared"]

    if args.volume:
        volumes += ["-v", args.volume + ":" + docker_home + "/project",
                    "-w", docker_home + "/project"]
    else:
        volumes += ["-w", docker_home + "/shared"]

    print("Starting up docker image...")
    if subprocess.check_output(["docker", "--version"]). \
            find(b"Docker version 1.") >= 0:
        rmflag = "-t"
    else:
        rmflag = "--rm"

    envs = ["--hostname", container,
            "--env", "HOST_UID=" + uid]
    # Start the docker image in the background and pipe the stderr
    subprocess.call(["docker", "run", "-d", rmflag, "--name", container,
                     "-p", "127.0.0.1:" + port_http + ":" + port_http] +
                    envs + volumes +
                    [args.image,
                     "jupyter-notebook --no-browser --ip=0.0.0.0 --port " +
                     port_http +
                     " >> " + docker_home + "/.log/jupyter.log 2>&1"])

    wait_for_url = True
    # Wait for user to press Ctrl-C
    while True:
        try:
            if wait_for_url:
                # Wait until the file is not empty
                while not subprocess.check_output(["docker", "exec", container,
                                                   "cat", docker_home +
                                                   "/.log/jupyter.log"]):
                    time.sleep(1)

                p = subprocess.Popen(["docker", "exec", container,
                                      "tail", "-F",
                                      docker_home + "/.log/jupyter.log"],
                                     stdout=subprocess.PIPE,
                                     stderr=subprocess.PIPE,
                                     universal_newlines=True)

                # Monitor the stdout to extract the URL
                for stdout_line in iter(p.stdout.readline, ""):
                    ind = stdout_line.find("http://0.0.0.0:")

                    if ind >= 0:
                        # Open browser if found URL
                        if not args.notebook:
                            url = "http://localhost:" + \
                                stdout_line[ind + 15:-1]
                        else:
                            url = "http://localhost:" + port_http + \
                                "/notebooks/" + args.notebook + \
                                stdout_line[stdout_line.find("?token="):-1]

                        print("Copy/paste this URL into your browser " +
                              "when you connect for the first time:")
                        print("    ", url)

                        if not args.no_browser:
                            webbrowser.open(url)

                        p.stdout.close()
                        p.terminate()
                        wait_for_url = False
                        break
            if args.detach:
                print('Started container ' + container + ' in background.')
                print('To stop it, use "docker stop ' + container + '".')
                sys.exit(0)

            print("Press Ctrl-C to stop the server.")

            # Wait till the container exits or Ctlr-C is pressed
            subprocess.check_output(["docker", "exec", container,
                                     "tail", "-f", "/dev/null"])
        except subprocess.CalledProcessError:
            try:
                # If Docker process no long exists, exit
                if not subprocess.check_output(['docker', 'ps',
                                                '-q', '-f',
                                                'name=' + container]):
                    print('Docker container is no longer running')
                    sys.exit(-1)
                time.sleep(1)
            except KeyboardInterrupt:
                handle_interrupt(container)

            continue
        except KeyboardInterrupt:
            handle_interrupt(container)
        except OSError:
            sys.exit(-1)
