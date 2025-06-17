# Shell scripts

If you're happy running things from the shell, the scripts in this directory may be useful to you. (Bash shell required.)

All scripts should be run from the repository root.

```sh
# Make the script executable
chmod +x run_app.sh

# Run the script from the repo root
./scripts/run_app.sh
```

## `dev.sh`

This runs the pre-commit hooks followed by the tests.

In case `pre-commit` is not installed or enabled, there is an R script `pre-commit.R` that goes part of the way there. This is run automatically in `dev.sh` if the `pre-commit` command fails.

## `run_app.sh`

This loads the development version of the package using `devtools::load_all()` and launches the app in the default browser.

## `cli_test.sh`

This runs the CLI with one of the preset personas and a small bounding box, saving the outputs to `tmp/`.
