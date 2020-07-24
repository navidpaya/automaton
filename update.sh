#!/bin/bash
time ansible-playbook --ask-become-pass -i hosts.ini workstation.yml
