from quixstreams import Application
import numpy as np
import os
import quixmatlab

# Initiate quixmatlab
quixmatlab_client = quixmatlab.initialize()
print("Exported MATLAB functions:", dir(quixmatlab_client))

# Define matlab function call
def matlab_processing(row: dict):
    # Prepare function inputs
    throttle_angle = row["throttle_angle"]
    input_matrix = np.array([[0, throttle_angle]])
    # print("Input", input_matrix)
    output_matrix = quixmatlab_client.simulink_wrapper(input_matrix)
    # print("Output", output_matrix)

    # Incorporating result to row
    row["crank_speed_rad/sec"] = output_matrix[0][0]
    row["engine_speed_rpm"] = output_matrix[0][1]
    

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