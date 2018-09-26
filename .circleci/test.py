import os

print os.environ('CIRCLE_JOB')
print os.environ('CIRCLE_SHA1')
print os.environ('CIRCLE_PROJECT_REPONAME')
