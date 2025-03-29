import yaml
import copy

# Load existing AMF and populate files
def load_yaml(filename):
    try:
        with open(filename, "r") as file:
            return yaml.safe_load(file) or {}
    except FileNotFoundError:
        return {}

amf_values = load_yaml("5gSA-values.yaml")

# Prepare dynamic taiList and s_nssai entries for AMF
tac_values = []
s_nssai_values = []

# Configure GNB parameters
num_gnbs = 3
initial_msisdn = 1

# Define slices for each GNB
gnb_slices = [
    {"sst": 1, "sd": "0x111111"},
    {"sst": 2, "sd": "0x222222"},
    {"sst": 3, "sd": "0x333333"}
]

# Define dynamic UE counts for each GNB
ue_counts = [2, 2, 1]

if len(ue_counts) != num_gnbs:
    raise ValueError("Number of UE counts does not match number of GNBs")

if len(gnb_slices) != num_gnbs:
    raise ValueError("Number of slices does not match number of GNBs")

# Generate multiple GNB configuration files
gnb_configs = []
msisdn_offset = initial_msisdn

for i in range(num_gnbs):
    # Configure GNB with the exact structure needed
    gnb = {
        "name": f"ueransim-gnb{i+1}",
        "amf": {
            "hostname": "open5gs-amf-ngap"
        },
        "mcc": "999",
        "mnc": "70",
        "tac": f"{i+1:04d}",
        "sd": gnb_slices[i]["sd"],
        "sst": gnb_slices[i]["sst"],
        "ues": {
            "enabled": True,
            "count": ue_counts[i],  # Dynamic count for each GNB
            "initialMSISDN": f"{msisdn_offset:010d}",
            "nodeSelector": {
                "role": "ueransim"
            },
            "apnList": [
                {
                    "apn": "internet",
                    "emergency": False,
                    "slice": {
                        "sst": gnb_slices[i]["sst"],
                        "sd": gnb_slices[i]["sd"]
                    },
                    "type": "IPv4"
                }
            ]
        },
        "nodeSelector": {
            "role": "ueransim"
        }
    }
    gnb_configs.append(gnb)

    # Update MSISDN offset for next GNB
    msisdn_offset += ue_counts[i]

    # Collect TAC values for AMF configuration
    tac_values.append(i+1)

    # Collect S_NSSAI values for AMF configuration
    s_nssai_entry = {
        "sst": gnb_slices[i]["sst"],
        "sd": gnb_slices[i]["sd"]
    }
    if s_nssai_entry not in s_nssai_values:
        s_nssai_values.append(s_nssai_entry)

# Update AMF configuration with dynamic taiList and plmnList
if "amf" not in amf_values:
    amf_values["amf"] = {}
if "config" not in amf_values["amf"]:
    amf_values["amf"]["config"] = {}

# Update taiList
amf_values["amf"]["config"]["taiList"] = [{
    "plmn_id": {
        "mcc": "999",
        "mnc": "70"
    },
    "tac": tac_values
}]

# Update plmnList with collected S_NSSAI values
amf_values["amf"]["config"]["plmnList"] = [{
    "plmn_id": {
        "mcc": "999",
        "mnc": "70"
    },
    "s_nssai": s_nssai_values
}]

# Update populate section with UE entries
populate_values = amf_values.get("populate", {})
populate_values["enabled"] = True

# Generate populate initCommands for UEs with appropriate slice info
populate_commands = []
ue_counter = 1

for i in range(num_gnbs):
    for j in range(ue_counts[i]):  # Use the dynamic count for each GNB
        populate_commands.append(
            f"open5gs-dbctl add_ue_with_slice 9997000000000{ue_counter:02d} "
            f"465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA "
            f"internet {gnb_slices[i]['sst']} {gnb_slices[i]['sd'].replace('0x', '')}"
        )
        ue_counter += 1

populate_values["initCommands"] = populate_commands
amf_values["populate"] = populate_values

# Save files
def save_yaml(filename, data):
    with open(filename, "w") as file:
        yaml.dump(data, file, default_flow_style=False)

# Save main 5gsa-values.yaml file
save_yaml("5gSA-values.yaml", amf_values)

# Save individual GNB files
for gnb in gnb_configs:
    # Create a clean copy
    gnb_file = copy.deepcopy(gnb)
    save_yaml(f"{gnb['name']}.yaml", gnb_file)

print("Files updated/generated successfully!")
