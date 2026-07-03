IDS="$@"
echo "Setting flash parameters for temp sensor(s) with ID(s): $IDS"
echo "Please ensure ecat is running in config_mode"

ecat list
ecat sdo write Upper_error_threshold 80
ecat sdo write Resistance 4700
ecat sdo write Constant_a1 0.2616
ecat sdo write Constant_a0 -261.0
ecat sdo read Constant_a0 Constant_a1 Resistance Scaled_measurement_value Analog_input_1_x2401 Analog_input
ecat cmd CIRCULO_SAVE_PARAMS --id $IDS
