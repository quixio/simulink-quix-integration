from quixstreams import Application
import numpy as np
import os
import json
import quixmatlab

# Initiate quixmatlab
quixmatlab_client = quixmatlab.initialize()
print("Exported MATLAB functions:", dir(quixmatlab_client))

# Default configuration (used if config is missing or invalid)
DEFAULT_CONFIG = {}


def prepare_config_json(config_data) -> str:
    """
    Prepare config data as a JSON string to pass to MATLAB.

    Handles:
        - Missing field (None) -> empty JSON object
        - Already a dict -> serialize to JSON string
        - Already a string -> validate and pass through
        - Invalid data -> empty JSON object

    Returns:
        str: Valid JSON string to pass to MATLAB wrapper
    """
    if config_data is None:
        return json.dumps(DEFAULT_CONFIG)

    # If it's already a dict, serialize to JSON string
    if isinstance(config_data, dict):
        return json.dumps(config_data)

    # If it's a string, validate it's valid JSON
    if isinstance(config_data, str):
        if not config_data.strip():
            return json.dumps(DEFAULT_CONFIG)
        try:
            # Validate JSON by parsing, then return original string
            json.loads(config_data)
            return config_data
        except json.JSONDecodeError as e:
            print(f"Warning: Invalid JSON in config field: {e}. Using empty config.")
            return json.dumps(DEFAULT_CONFIG)

    print(f"Warning: Unexpected config type: {type(config_data)}. Using empty config.")
    return json.dumps(DEFAULT_CONFIG)


# Define matlab function call
def matlab_processing(row: dict):
    # Prepare function inputs from Kafka data
    x = row["x"]
    y = row["y"]

    # Prepare config JSON to pass directly to MATLAB
    config_json = prepare_config_json(row.get("config"))

    # Build input matrix: [time, x, y]
    # Config parameters are passed separately via JSON to the MATLAB wrapper
    input_matrix = np.array([[0, x, y]])

    # Pass both input matrix and config JSON to MATLAB wrapper
    output_matrix = quixmatlab_client.simulink_wrapper(input_matrix, config_json)

    # Incorporating result to row
    row["x_new"] = output_matrix[0][0]
    row["y_new"] = output_matrix[0][1]
    

def main():
    # Setup necessary objects
    app = Application(
        consumer_group="CompilerSDKMatlab2024b_wheel_general",
        auto_create_topics=True,
        auto_offset_reset="earliest"
    )
    input_topic = app.topic(name=os.environ["input"])
    output_topic = app.topic(name=os.environ["output"])
    sdf = app.dataframe(topic=input_topic)
    

    # Do StreamingDataFrame operations/transformations here
    sdf.print_table()
    sdf = sdf.update(matlab_processing)
    sdf.print_table()

    # Finish off by writing to the final result to the output topic
    sdf.to_topic(output_topic)

    # With our pipeline defined, now run the Application
    app.run()


# It is recommended to execute Applications under a conditional main
if __name__ == "__main__":
    main()