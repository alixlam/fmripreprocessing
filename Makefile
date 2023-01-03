VENV_PREFIX=$(shell python -c "if __import__('pathlib').Path('.venv/bin/pip').exists(): print('.venv/bin/')")
DATA_FOLDER="/users2/local/alix/XP2"
IMAGE_DIR="/users/local/alix/singularity_images/fmriprep-22.0.2.simg"
OUT_FOLDER="/users2/local/alix/out"
WORK_FOLDER="/users2/local/alix/work"
LICENSE_PATH="/homes/a19lamou/fmripreprocessing/.licenses/license.txt"

.PHONY: run-singularity --DATA_FOLDER --WORK_FOLDER --OUT_FOLDER
run-singularity: # Run singularity 
	@echo "Running singularity on data in [$(DATA_FOLDER)]"
	@singularity run -B /homes/a19lamou/fmripreprocessing:/fmripreprocessing -B $(DATA_FOLDER):/data -B $(WORK_FOLDER):/work -B $(OUT_FOLDER):/out $(IMAGE_DIR) /data /out participant --fs-license-file /fmripreprocessing/.licenses/license.txt --work-dir /work --force-no-bbr --fs-no-reconall --output-spaces MNI152NLin2009cAsym:res-2 anat func 

.PHONY: generate-report --DATA_FOLDER
generate-report:
	@echo "Generating report"
	@singularity run -B /homes/a19lamou/fmripreprocessing:/fmripreprocessing -B $(DATA_FOLDER):/data -B ${PWD}/out:/out $(IMAGE_DIR) /data /out participant --fs-license-file /fmripreprocessing/.licenses/license.txt --report

.PHONY: run
run: # Run code
	@echo "Run code"
	@$(VENV_PREFIX)python -m fmripreprocessing.__main__

.PHONY: venv
venv: # Create virtual environment
	@echo "Create virtual environment"
	@rm -rf .venv
	@python3 -m venv .venv
	@./.venv/bin/pip install -U pip
	@./.venv/bin/pip install -e .[test]
	@export ANTSPATH=/opt/ANTs/bin/
	@export PATH=${ANTSPATH}:$PATH
	@echo "Run --> source .venv/bin/activate to activate environment"


.PHONY: fmt
fmt: # Run autopep8, isort, and black
	@echo "Format code and sort imports"
	@$(VENV_PREFIX)autopep8 -i -a -a -r fmripreprocessing
	@$(VENV_PREFIX)isort --profile black -w 79 fmripreprocessing
	@$(VENV_PREFIX)black -l 79 fmripreprocessing
	@$(VENV_PREFIX)autopep8 -i -a -a -r scripts
	@$(VENV_PREFIX)isort --profile black -w 79 scripts
	@$(VENV_PREFIX)black -l 79 scripts
	@echo "Format finished!"

.PHONY: lint
lint: # Run pylint and pycodestyle
	@echo "Run linter"
	@$(VENV_PREFIX)black -l 79 --check fmripreprocessing
	@$(VENV_PREFIX)pycodestyle --ignore E203,W503,W504 fmripreprocessing
	@$(VENV_PREFIX)pylint fmripreprocessing
	@echo "Linter okay!"


.PHONY: clean
clean: # Clean unused files
	@find ./ -name '*.pyc' -exec rm -f {} \;
	@find ./ -name '__pycache__' -exec rm -rf {} \;
	@find ./ -name 'Thumbs.db' -exec rm -f {} \;
	@find ./ -name '*~' -exec rm -f {} \;
	@rm -rf .cache
	@rm -rf .pytest_cache
	@rm -rf .mypy_cache
	@rm -rf build
	@rm -rf dist
	@rm -rf *.egg-info
	@rm -rf htmlcov
	@rm -rf .tox/
	@rm -rf docs/_build

.PHONY: docker-image
docker-image: # Create Docker image
	@echo "Creating docker image"
	@docker build --rm -t  fmripreprocessing\
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		--build-arg VERSION=`python get_version.py` .

.PHONY: docker-container
docker-container:
	@echo "Creating docker container"
	@docker create -it  \
		-v ${PWD}/fmripreprocessing:/home/fmripreprocessing \
		-v ${PWD}/data:/home/data \
		--name container-fmripreprocessing fmripreprocessing




# .PHONY: build
# build: # Build package
#	@echo "Build package"
#	@python3 -m build