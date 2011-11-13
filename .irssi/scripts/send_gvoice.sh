#!/bin/bash

# ~/.gvoice must exist and defined!
gvoice send_sms 2144314654 $1 2>&1 >/dev/null
