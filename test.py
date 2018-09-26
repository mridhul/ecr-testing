import os


if __name__ == '__main__':
    yh = (
        os.environ['CIRCLE_JOB'],
        os.environ['CIRCLE_SHA1'],
        os.environ['CIRCLE_PROJECT_REPONAME'],
    )


print yh
