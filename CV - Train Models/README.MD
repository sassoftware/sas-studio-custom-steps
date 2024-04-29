CV - Train Models
==============================

This custom step helps users develop computer vision models to accomplish one of four prediction tasks:
	1. Image classification
	2. Image regression
	3. Object detection
	4. Multi-task

This step (tool) partitions the data, resizes the images, train a convolutional neural network, and enables the user to perform a neural architecture and hyperparameter search using SAS autotune's Evolutional Algorithm Guiding Local Search (EAGLS). 

The user can choose between several model backbones (underlying framework) and modify the backbone/framework to suit their data needs best. Certain features that define the model are task-specific, meaning they only appear when a corresponding task (object detection, classification, regression, or multi-task) is selected. Other features are task agnostic and will occur regardless of the chosen tasks.    

If autotuning is selected, the final model architecture and weights are saved, and training is resumed with an updated learning rate. That is, the new learning rate reflects the characteristics of the learning rate policy used during autotuning. If autotuning is not selected, a model is trained using the criteria listed in the input parameters.  

The step creates an output table that contains reference information needed for the Save Model and Score Data CV custom steps. The trained model and other important files are stored in the project folder (see "General Setup Details" below for more information).

NOTES: 
The model SASHDAT tables will need to be downloaded from: https://support.sas.com/documentation/prod-p/vdmml/zip/index.html
Only the following sashdats may be used in the current version of the step: 
     Object detection using Tiny YoloV2
     ResNet50 Caffe 
     ShuffleNetV2
     Xception

The step saves the log information into the project folder location specified by the user.  The project folder location must sit on the SAS Server and must not reside in the SAS Content folder.

# General Setup Details

## Project Setup Parameters
Specify project folder path (Required): provide a valid path to a folder located in the SAS Server that will be used to store important files generated from the step. 
These files include:

1. Autotuning results in html format.

2. Autotuned weights (autotune_bestweights_.sashdat) and attributes (autotune_bestweights_.ATTRS.sashdat) in sashdat format. 

3. Model table sashdat.

4. Model weights sashdat derived from final model training.

5. Model weight attributes sashdat derived from final model training.  

6. Folder containing a sample of holdout data detections for human-in-the-loop inspection (object detection only).

7. Log files for each autotuned evaluation and "global" log file containing all other SAS log information. 


Specify the path to the folder containing the model tables (Required): provide a valid path to a folder located in the SAS Server that contains the following case-sensitive sashdat files (can be downloaded from the Git repository):

resnet50_caffe.sashdat
resnet50_caffe_weights.sashdat
resnet50_caffe_weights_attr.sashdat

Tiny-Yolov2.sashdat
Tiny-Yolov2_weights.sashdat
Tiny-Yolov2_weights_attr.sashdat

ShuffleNetV2.sashdat
ShuffleNetV2_weights.sashdat
ShuffleNetV2_weights_attr.sashdat

## Modeling Task Setup Parameters
Choose a modeling task (Required): select from one of the four modeling task. Choices are object detection, classification, regression, or multi-task. 

Choose the error function to use for regression estimation (Required, regression task only): select from one of the five error functions. Choices are Normal, Poisson, Gamma, L1, and Cross-entropy.

Choose the activation (inverse link) function to use for regression estimation (Required, regression task only): select from one of the four inverse link functions. Choices are identity, exponential, logistic, and sine.

Use GPUs: select whether to use GPUs for model training. Ensure you have one or more Nvidia GPUs installed with the appropriate drivers. See SAS documentation, "Requirements for GPU Support" for more details.

##  Data Setup Parameters
Name of target variable (Required for regression and classification task only): provide the name of the target variable column.

Number of target (outcome) variables for multi-task learning (Required for multi-task only): provide the number of target outcomes. The number must reside within the range of 2 and 21, inclusive. 

Name of target variable 0 to 20 (Required for multi-task only): provide the names of the target variable columns in each respective text box.

Name of variable (column) containing image binary large object (BLOB) (Required): provide the name of the variable column containing the image BLOB.

Image size (Required): provide the input image size relative to the number of pixels. The step will resize the images to the specified size. For object detection task, the user must choose an image size from a drop-down with values of 224, 416, 640, or 1280. For classification, regression and multi-task problems, users can specify a customized size as long as the image width and height  is greater than or equal to 64 pixels.

Number of classes in the object detection data (Required for object detection task only): specify the number of classes present in your data.  

Number of image channels (Required): select the number of channels present in your image data. Choices are 3-channel for color images or single channel for greyscale images. The image data does not have to naturally conform the selected channel. The step will apply a transformation based on the user's selection for this parameter.

Apply photomorphic image mutations (Required): specify whether or not to apply random photomorphic mutations to mini-batches during the training process. If “random” is selected, SAS will mutate images using one of the following methods chosen at random: color jittering, sharpening, or lightening. Approximately half of the input data is subject to the photomorphic mutations. 

Apply random flipping (Required): specify whether or not to apply random “flip” mutations to mini-batches during the training process. Choices are none, horizontal, vertical, or both horizontal and vertical. Approximately half of the input data is subject to flipping.

Apply random cropping mutations (Required): specify whether or not to apply a cropping mutation. If “Resize then crop” is chosen from the drop-down list, SAS resizes images to 115% of the size of the input layer while maintaining the image aspect ratio. The smaller dimension (width or height) of the original input image size is resized to 115% of the input layer size, then the remaining dimension is resized to match the original image aspect ratio. The last step extracts a random crop (equal to the size of the input layer) from the interim image. No further resizing is required.

Specify the maximum number of possible bounding box anchors (Required for object detection only): specifies the maximum number of clusters to be searched when determining the optimal number of anchor boxes.

Specify the criterion to be used to estimate the number of appropriate bounding box anchors to use (Required for object detection only): specifies the criterion to be used to estimate the number of anchor boxes that use the statistics obtained by the ABC method. PROC KCLUS is used to apply clustering to the width and height of the ground truth bounding boxes. The user selects one of the following options from the drop-down list. “First peak” uses the first peak value among the peak values in gap statistics. “First maximum with standardization” uses the smallest k such that the gap value for that k is greater than the one-standard-error adjusted gap value for k+1. “Global peak” uses the maximum peak value among all the peak values in gap statistics. “All - majority selects” selects the number of anchor boxes based on which number of anchor boxes is chosen the most often from all methods included in the drop-down list. If each option selects a different number of anchor boxes, then the number selected by “Global peak” is used.

Percentage of validation cases (Required): specify the percentage of data to be allocated to the holdout data.

Name of partition variable (designates training vs. holdout) (Required): specify the name of partition indicator that will be added to the data.

Random partition seed (Required): specifies an integer that is used to start the pseudorandom number generator. If you do not specify a seed or you specify a value less than or equal to 0, the seed is generated from reading the time of day from the computer’s clock. 

# Modeling Options Details

## Autotune Parameters
Do you want to autotune the model (Required)? user specifies whether to use SAS autotune's Evolutional Algorithm Guiding Local Search (EAGLS).

Name of the table to create with autotune results (Required): specifies the name of the sashdat table that will contain the results from autotuning. The table is saved in the project folder.

Do you want to leverage a previous search (Required)? user specifies whether to use a previous search in the current execution. Leveraging previous autotune executions is valuable in computer vision modeling because evaluations may take long periods of time. In addition, breaking up the search across executions enables the user to examine the results and make adjustments to the search, meaning human-in-the-loop neural architecture search is supported by this step. 

Name of the table to create with previous autotune results (Required): specifies the name of the sashdat table that contains results from a previous autotuning execution. The table should be stored/located in the project folder.


Specify the number of previous strong performing evaluations to use in (seed) the next search (Required): specifies the number of previous strong performing evaluations to use in the current search. That is, the number indicates how many best performing evaluations will be retrained and used to influence the current EAGLS search. For example, a value of “3” will retrain the three best performers included in the previous search table.  

Random seed for autotune (Required): specifies the random seed to use when autotuning. It is very important to change the random seed if the user is leveraging a previous autotune search.

Starting population (evaluations in initial sample) (Required):  specifies the initial number of samples to be drawn from a Latin hypercube sample.  

Number of generations (Required):  specifies the number of generations used by EAGLS. Each generation will perform the following steps, selection, crossover, mutation and generating set search. Selection, crossover and mutation are natural elements of the genetic algorithm. The generating set search is a greedy algorithm that searches from the current best performing evaluations. 

Number of local permutations (greedy search) (Required): specifies the number of permutations created from the generating set search. These evaluations are considered a local, greedy search. Increasing this value will cause the population to more aggressively become homogenous.  

Number of epochs per evaluation (Required): specifies the number of epochs to train each evaluation during the autotuning process.

Maximum number of seconds to spend on search (Required): specifies the number of seconds to execute autotune. 

Name of HTML file containing autotune results (Required): specify the name of the HTML file that will contain the results. The results HTML file will be stored in the project folder.

## Model Specifications Parameters
Number of threads to use (Required): specifies the number of threads to use when training the mode. Increasing threads may increase training speed but will also increase memory usage and can cause failed executions when the system memory is exceeded. Suggested values are 4, 8 or 12.

Search weight for object's presence error (Required for object detection only): specifies whether to use SAS Autotune to search for an optimal value.

Object present scalar (Required for object detection only): specifies the scalar value to use for determining if an object is present in a cell. That is, this value influences the “value” the corresponding partial error has over the weight updates. 

Object present, lower bound scalar (Required for object detection only): specifies the lower bound scalar for SAS autotune’s search of the object’s presence scalar.

Object present, upper bound scalar (Required for object detection only): specifies the upper bound scalar for SAS autotune’s search of the object’s presence scalar.
	
Search weight for object's absence error (Required for object detection only): specifies whether to use SAS Autotune to search for an optimal value.

No Object present scalar (Required for object detection only): specifies the scalar value to use for determining if an object is not present (absent) in a cell. That is, this value influences the “value” the corresponding partial error has over the weight updates. 

No object present, lower bound scalar (Required for object detection only): specifies the lower bound scalar for SAS autotune’s search of the object’s absence scalar.

No object present, upper bound scalar (Required for object detection only): specifies the upper bound scalar for SAS autotune’s search of the object’s absence scalar.

Search weight for object's coordinate error (Required for object detection only): specifies whether to use SAS Autotune to search for an optimal value.

Object coordinate scalar (Required for object detection only): specifies the scalar value to use for determining an object’s location in the image and bounding box size (offsets from the anchor boxes). That is, this value influences the “value” the corresponding partial error has over the weight updates.

Object coordinate, lower bound scalar (Required for object detection only): specifies the lower bound scalar for SAS autotune’s search of the object’s location in the image and bounding box size estimation.

Object coordinate, upper bound scalar (Required for object detection only): specifies the upper bound scalar for SAS autotune’s search of the object’s location in the image and bounding box size estimation.

Search weight for classification error (Required for object detection only): specifies whether to use SAS Autotune to search for an optimal value.

Object classification scalar (Required for object detection only): specifies the scalar value to use for determining an object’s classification. That is, this value influences the “value” the corresponding partial error has over the weight updates.

Object classification, lower bound scalar (Required for object detection only): specifies the lower bound scalar for SAS autotune’s search of the object’s classification.

Object classification, upper bound scalar (Required for object detection only): specifies the upper bound scalar for SAS autotune’s search of the object’s classification.

Search detection threshold (Required for object detection only): specifies whether to use SAS Autotune to search for an optimal value.

Detection threshold (Required for object detection only): specifies the threshold for probability in object detection. 

Detection threshold, lower bound (Required for object detection only): specifies the lower bound threshold for SAS autotune’s search of the detection threshold.

Detection threshold, upper bound (Required for object detection only): specifies the upper bound threshold for SAS autotune’s search of the detection threshold.

Search intersection over union (IoU) threshold (Required for object detection only): specifies whether to use SAS Autotune to search for an optimal value.

IoU threshold (Required for object detection only): specifies the scalar value to use for determining the IoU threshold for maximum suppression in object detection. That is, this value influences the “value” the corresponding partial error has over the weight updates.

IoU threshold, lower bound (Required for object detection only): specifies the lower bound threshold for SAS autotune’s search of the IoU threshold for maximum suppression.

IoU threshold, upper bound (Required for object detection only): specifies the upper bound threshold for SAS autotune’s search of the IoU threshold for maximum suppression.

Search training intersection over union (IoU) threshold (Required for object detection only): specifies whether to use SAS Autotune to search for an optimal value.

Train IoU threshold (Required for object detection only): specifies the scalar value to use for determining the IoU threshold to determine a positive sample for training in object detection. That is, this value influences the “value” the corresponding partial error has over the weight updates.

Train IoU threshold, lower bound (Required for object detection only): specifies the lower bound threshold for SAS autotune’s search of the IoU threshold to determine a positive sample for training in object detection.

Train IoU threshold, upper bound (Required for object detection only): specifies the upper bound threshold for SAS autotune’s search of the IoU threshold to determine a positive sample for training in object detection.

Add a projection layer (1 by 1 convolutional) before the output layer(s) (Required for classification, regression and multi-task): specifies whether to insert a projection layer in between the tensor and the final model output.  Projection layers are used for tensor compression or expansion. If set to “yes”, options will appear that allow the user to choose the number of convolutional filters and nonlinear activation function to use.


## Final Model Training Parameters
Number of epochs (Required): specifies the number of epochs the final model will be trained. The final model’s full training horizon is equal to the number of epochs each trained during autotune plus the number of epochs specified in this parameter.

Name of final model weights table (Required): provide the name of the sashdat table that will contain the model’s final weights, as well as the table containing the weight attributes. That is, the value in the text box will be used for both the weights and attributes table with he attributes table having an additional suffix indicating the table contains attributes. Both tables will be stored in the project folder.

Percentage of holdout data to view (Required for object detection only): specifies the percentage of holdout data that will have the model’s prediction superimposed and printed for viewing.  

Created / contact : 
- Robert Blanchard (robert.blanchard@sas.com)


Version: 6.0.   (25MAR2024)