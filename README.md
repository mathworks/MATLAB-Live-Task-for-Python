# MATLAB Live Task for Python

[![View MATLAB Live Task for Python on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/111240-matlab-live-task-for-python)

The MATLAB® Live Task for Python® enables you to write and execute Python code directly inside of a MATLAB Live Script. Since R2022a, MATLAB provides a way to develop your own [custom live task](https://www.mathworks.com/help/matlab/creating_guis/live-task-development-overview.html).

---

## Requirements
### Required MathWorks Products
* MATLAB R2022a or later

### Required 3rd Party Products
* Python (supported Python versions by MATLAB release can be found [here](https://www.mathworks.com/support/requirements/python-compatibility.html))

---

## Install
Run the `install` script to add the required paths to your MATLAB environment and configure the MATLAB Live Task for Python. Click 'Ok' when promtped with the following UI to configure the Live Editor task metadata:

![img/pythonTaskInstall.png](img/pythonTaskInstall.png)

---

## Getting Started
To insert the live task in your live script:

1. Go to the Live Editor tab in the Editor Toolstrip and select Task: 

    ![img/pythonTask1.png](img/pythonTask1.png)

2. Then, choose the live task under the MY TASKS category:

    ![img/pythonTask2.png](img/pythonTask2.png)

Alternatively you may simply type `python` and the autocomplete feature will suggest the appropriate task:

![img/pythonTask3.png](img/pythonTask3.png)

This is what the MATLAB Live Task for Python looks like:

![img/pythonTask4.png](img/pythonTask4.png)

First, create a variable in the MATLAB workspace: 
```
>> T = 'We at MathWorks believe in the importance of engineers and scientists. They increase human knowledge and profoundly improve our standard of living.';
```

The Python input and output variables can be mapped with variables in the MATLAB workspace: 

![img/pythonTask5.png](img/pythonTask5.png)

You can choose to write either Python statements or a Python script file: 

![img/pythonTask6.png](img/pythonTask6.png)

and retrieve the required variables to be used back in MATLAB:

![img/pythonTask7.png](img/pythonTask7.png)

The equivalent MATLAB code to run either the Python statements (using [`pyrun`](https://www.mathworks.com/help/matlab/ref/pyrun.html)) or a Python script (using [`pyrunfile`](https://www.mathworks.com/help/matlab/ref/pyrunfile.html)) is generated and run automatically by default like any live task:

![img/pythonTask8.png](img/pythonTask8.png)

```
>> wrapped = string(wrapped)'

wrapped = 

  6×1 string array

    "% We at MathWorks believe in"
    "% the importance of engineers"
    "% and scientists. They"
    "% increase human knowledge and"
    "% profoundly improve our"
    "% standard of living."
```

---

## Examples

You can find examples on how to use the MATLAB Live Task for Python in the `examples` folder within this repository.

---

## Support

Technical issues or enhancement requests can be submitted [here](https://github.com/mathworks/MATLAB-Live-Task-for-Python/issues).

---

## License
The license is available in the License file within this repository

Copyright © 2022 MathWorks, Inc. All rights reserved.

"Python" is a registered trademark of the Python Software Foundation.