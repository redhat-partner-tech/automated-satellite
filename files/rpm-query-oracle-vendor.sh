#!/bin/bash
rpm -qa --queryformat '%{vendor}:%{name}\n' | grep 'Oracle America'
