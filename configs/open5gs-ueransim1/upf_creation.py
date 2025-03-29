import yaml
import sys

def generate_upf_values_yaml(num_upfs):
    for i in range(1, num_upfs + 1):
        upf_data = {
            "nodeSelector": {"role": "data_plane"},
            "config": {"pfcp": {"hostname": f"open5gs-upf{i}-pfcp", "address":"open5gs-smf-pfcp"}},
        }
        with open(f"upf{i}-values.yaml", "w") as file:
            yaml.dump(upf_data, file, default_flow_style=False)
    print(f"Generated {num_upfs} UPF configuration files.")

def modify_5gsa_values_yaml(num_upfs, input_file="5gSA-values.yaml", output_file="5gSA-values-modified.yaml"):
    with open(input_file, "r") as file:
        data = yaml.safe_load(file)

    upf_hostnames = [f"open5gs-upf{i}-pfcp" for i in range(1, num_upfs + 1)]
    data["smf"]["config"]["upf"]["pfcp"]["hostnames"] = upf_hostnames

    with open(output_file, "w") as file:
        yaml.dump(data, file, default_flow_style=False)
    print(f"Modified 5gSA-values.yaml with {num_upfs} UPFs and saved as {output_file}.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <num_upfs>")
        sys.exit(1)

    num_upfs = int(sys.argv[1])
    generate_upf_values_yaml(num_upfs)
    modify_5gsa_values_yaml(num_upfs,output_file="5gSA-values.yaml")
