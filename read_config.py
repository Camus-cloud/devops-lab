import yaml, sys
with open("config.yaml") as f:
    config = yaml.safe_load(f)
print(config.get(sys.argv[1]))
