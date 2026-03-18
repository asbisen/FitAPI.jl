# Create Profile

Script to generate profile.msg that contains Garmin Profile in msgpack format. This
generated output would be used in FitIO to import the profile.

## Usage

```bash
uv sync --upgrade # upgrade to the latest version of garmin-fit-sdk
uv run generate_fit_profile.py # generate profile.msg in the current directory
cp profile.msg ../../src/msgpack/ # move the profile.msg to the src/msgpack directory of FitIO
```
