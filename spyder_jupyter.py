#!/usr/bin/env python

"""
Launch Jupyter Notebook within a Docker notebook image and
automatically open up the URL in the default web browser. It also
sets up port forwarding for ssh and X11 forwarding.
"""

# Author: Xiangmin Jiao <xmjiao@gmail.com>

from __future__ import print_function

import sys
import subprocess
import time
import os

owner = "compdatasci"
proj = os.path.basename(sys.argv[0]).split('_')[0]
image = owner + '/' + proj + "-desktop"
tag = ""
projdir = "project"
workdir = "shared"
volume = proj + "_project"


def parse_args(description):
    "Parse command-line arguments"

    import argparse

    # Process command-line arguments
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument('-i', '--image',
                        help='The Docker image to use. ' +
                        'The default is ' + image + '.',
                        default=image)

    parser.add_argument('-t', '--tag',
                        help='Tag of the image. The default is latest. ' +
                        'If the image already has a tag, its tag prevails.',
                        default=tag)

    parser.add_argument('-v', '--volume',
                        help='A data volume to be mounted at ~/" + projdir + ". ' +
                        'The default is ' + proj + '_project.',
                        default=volume)

    parser.add_argument('-w', '--workdir',
                        help='The starting work directory in container. ' +
                        'The default is ~/' + workdir + '.',
                        default=workdir)

    parser.add_argument('-p', '--pull',
                        help='Pull the latest Docker image. ' +
                        'The default is not to pull.',
                        action='store_true',
                        default=False)

    parser.add_argument('-r', '--reset',
                        help='Reset configurations to default.',
                        action='store_true',
                        default=False)

    parser.add_argument('-c', '--clear',
                        help='Clear the project data volume (please use with caution).',
                        action='store_true',
                        default=False)

    parser.add_argument('-d', '--detach',
                        help='Run in background and print container id',
                        action='store_true',
                        default=False)

    parser.add_argument('-n', '--no-browser',
                        help='Do not start web browser',
                        action='store_true',
                        default=False)

    parser.add_argument('-N', '--nvidia',
                        help='Mount the Nvidia card for GPU computation. ' +
                        '(Linux only, experimental, sudo required).',
                        action='store_true',
                        default="")

    parser.add_argument('-V', '--verbose',
                        help='Enable verbose mode and print debug info to stderr.',
                        action='store_true',
                        default=False)

    parser.add_argument('-q', '--quiet',
                        help='Disable screen output (some Docker output cannot be disabled).',
                        action='store_true',
                        default=False)

    parser.add_argument('-A', '--args',
                        help='Additional arguments for the "docker run" command. ' +
                        'Useful for specifying additional resources or environment variables.',
                        default="")

    parser.add_argument('-J', '--jupyter',
                        help='Additional arguments for jupyter-notebook.',
                        default="")

    parser.add_argument('notebook', nargs='?',
                        help='The notebook to open.', default="")

    args = parser.parse_args()

    # Append tag to image if the image has no tag
    if args.image.find(':') < 0:
        if not args.tag:
            pass
        else:
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
    return proj + "-" + (''.join(random.choice(chars) for _ in range(size)))


def get_local_ip():
    "Get the local IP address"
    import socket

    # https://stackoverflow.com/questions/166506/finding-local-ip-addresses
    return [l for l in ([ip for ip in
                         socket.gethostbyname_ex(socket.gethostname())[2]
                         if not ip.startswith("127.")][:1],
                        [[(s.connect(('8.8.8.8', 53)), s.getsockname()[0], s.close())
                          for s in [socket.socket(socket.AF_INET, socket.SOCK_DGRAM)]][0][1]])
            if l][0][0]


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

    return ''


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
    import webbrowser
    import platform
    import re
    import glob

    args = parse_args(description=__doc__)
    config = proj + '_' + args.tag + '_config'

    if args.quiet:
        def print(*args, **kwargs):
            "Do nothing"
            pass

        def stdout_write(*args, **kwargs):
            "Do nothing"
            pass

        def stderr_write(*args, **kwargs):
            "Do nothing"
            pass
    else:
        def stdout_write(*args, **kwargs):
            "Call sys.stderr.write"
            sys.stdout.write(*args, **kwargs)

        def stderr_write(*args, **kwargs):
            "Call sys.stderr.write"
            sys.stderr.write(*args, **kwargs)

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
        if uid == '0':
            print('You are running as root. This is not safe. ' +
                  'Please run as a regular user.')
            sys.exit(-1)
    else:
        uid = ""

    try:
        if args.verbose:
            stdout_write("Check whether Docker is up and running.\n")
        img = subprocess.check_output(['docker', 'images', '-q', args.image])
    except:
        stderr_write("Docker failed. Please make sure docker was properly " +
                     "installed and has been started.\n")
        sys.exit(-1)

    if args.pull or not img:
        try:
            if args.verbose:
                stdout_write("Pulling latest docker image " +
                             args.image + '.\n')
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

    docker_user = "ubuntu"
    docker_home = "/home/" + docker_user

    if args.reset:
        try:
            if args.verbose:
                stdout_write("Removing old docker volume " + config + ".\n")
            output = subprocess.check_output(
                ["docker", "volume", "rm", "-f", config])
        except subprocess.CalledProcessError as e:
            stderr_write(e.output.decode('utf-8'))

    volumes = ["-v", pwd + ":" + docker_home + "/shared",
               "-v", config + ":" + docker_home + "/.config"]

    if os.path.exists(homedir + "/.gnupg"):
        volumes += ["-v", homedir + "/.gnupg" +
                    ":" + docker_home + "/.gnupg"]

    # Mount .gitconfig to Docker image
    if os.path.isfile(homedir + "/.gitconfig"):
        volumes += ["-v", homedir + "/.gitconfig" +
                    ":" + docker_home + "/.gitconfig_host"]

    if args.volume:
        if args.clear:
            try:
                if args.verbose:
                    stdout_write(
                        "Removing old docker volume " + config + ".\n")
                output = subprocess.check_output(["docker", "volume",
                                                  "rm", "-f", args.volume])
            except subprocess.CalledProcessError as e:
                stderr_write(e.output.decode('utf-8'))

        volumes += ["-v", args.volume + ":" + docker_home + "/" + projdir]

    if args.workdir[0] == '/':
        volumes += ["-w", args.workdir]
    else:
        volumes += ["-w", docker_home + "/" + args.workdir]

    stderr_write("Starting up docker image...\n")
    if subprocess.check_output(["docker", "--version"]). \
            find(b"Docker version 1.") >= 0:
        rmflag = "-t"
    else:
        rmflag = "--rm"

    # Generate a container ID
    container = id_generator()

    envs = ["--hostname", container,
            "--env", "HOST_UID=" + uid]

    # Find a free port for ssh tunning
    port_ssh = str(find_free_port(2222, 50))
    if not port_ssh:
        stderr_write("Error: Could not find a free port.\n")
        sys.exit(-1)
    envs += ["-p", port_ssh + ":22"]

    # Create directory .ssh if not exist
    if not os.path.exists(homedir + "/.ssh"):
        os.mkdir(homedir + "/.ssh")

    volumes += ["-v", homedir + "/.ssh" + ":" + docker_home + "/.ssh"]

    devices = []
    if args.nvidia:
        for d in glob.glob('/dev/nvidia*'):
            devices += ['--device', d + ':' + d]

    # set up X11 forwarding for Mac or Linux if DISPLAY is set
    if platform.system() != 'Windows' and 'DISPLAY' in os.environ:
        # Mac OS X by default does not support X11 forwarding
        # and its DISPLAY environment variable cannot be shared
        envs += ["--env", "DISPLAY=" + get_local_ip() + ":0"]
        if os.path.exists('/usr/X11/bin/xhost') or os.path.exists('/usr/bin/xhost'):
            subprocess.check_output(['xhost', '+' + get_local_ip()])

    # Start the docker image in the background and pipe the stderr
    port_http = str(find_free_port(8888, 50))
    if not port_http:
        stderr_write("Error: Could not find a free port.\n")
        sys.exit(-1)

    cmd = ["docker", "run", "-d", rmflag, "--name", container,
           "--shm-size", "2g", "-p", port_http + ":" + port_http] + \
        envs + volumes + args.args.split() + \
        ['--security-opt', 'seccomp=unconfined', '--cap-add=SYS_PTRACE', args.image,
            "jupyter-notebook --no-browser --ip=0.0.0.0 --port " +
            port_http + " " + args.jupyter +
            " >> " + docker_home + "/.log/jupyter.log 2>&1"]

    if args.verbose:
        stdout_write(' '.join(cmd[:-1]) + ' "' + cmd[-1] + '"\n')

    subprocess.call(cmd)

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
                    if args.verbose:
                        stdout_write(stdout_line)

                    m = re.search('http://[^:]+:', stdout_line)

                    if m:
                        # Open browser if found URL
                        if not args.notebook:
                            url = "http://localhost:" + \
                                stdout_line[m.end():-1]
                        else:
                            url = "http://localhost:" + port_http + \
                                "/notebooks/" + args.notebook + \
                                stdout_line[stdout_line.find("?token="):-1]

                        print("Copy/paste this URL into your browser " +
                              "when you connect for the first time:")
                        print("    ", url)

                        stdout_write("You can also log into the container using the command\n    ssh -X -p " + port_ssh + " " +
                                     docker_user + "@localhost -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no\n" +
                                     "with an authorized key in " +
                                     homedir + "/.ssh/authorized_keys.\n")

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
            time.sleep(1)

            # Wait until the container exits or Ctlr-C is pressed
            if not args.quiet:
                if args.verbose:
                    stdout_write("Redirecting ~/.log/jupyter.log to stdout.\n")

                subprocess.call(["docker", "exec", container,
                                 "tail", "-F", "-n", "0",
                                 docker_home + "/.log/jupyter.log"])
            else:
                subprocess.call(["docker", "exec", container,
                                 "tail", "-f", "/dev/null"])
            sys.exit(0)

        except subprocess.CalledProcessError:
            try:
                # If Docker process no long exists, exit
                if args.verbose:
                    stdout_write(
                        "Check whether docker container is running.\n")
                if not subprocess.check_output(['docker', 'ps',
                                                '-q', '-f',
                                                'name=' + container]):
                    stdout_write('Docker container ' +
                                 container + ' is no longer running\n')
                    sys.exit(-1)
                else:
                    time.sleep(1)
                    continue
            except subprocess.CalledProcessError:
                stderr_write('Docker container ' +
                             container + ' is no longer running\n')
                sys.exit(-1)
            except KeyboardInterrupt:
                handle_interrupt(container)

            continue
        except KeyboardInterrupt:
            handle_interrupt(container)
        except OSError:
            sys.exit(-1)
