#!/bin/sh
set -eux

npx prisma migrate deploy
exec node ./bin/www