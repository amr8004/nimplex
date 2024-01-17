# Copyrigth (C) 2023 Adam M. Krajewski
{.passC: "-flto -ffast-math".} 
{.passL: "-flto".} 

from std/math import binom, ln
import std/sugar
import std/times
import std/strutils

when appType != "lib":
    import std/os

import arraymancer/Tensor
import arraymancer/io

import nimpy

## **NIM** sim**PLEX**: A concise scientific Nim library (with CLI and Python binding) providing samplings, uniform grids, and traversal graphs in compositional (simplex) spaces.
## 
## ## Installation
## There are several **easy** ways to quickly get *nimplex* up and running on your system. The choice depends primarily on your preffered way of interacting with the library (CLI, Nim, or Python) and your system configuration.
## 
## If you happen to be on one of the common systems (for which we auto-compile the binaries) and you do not need to modify anything in the source code, you can simply download the latest release from the [nimplex GitHub repository](https://github.com/amkrajewski/nimplex)
## and run the executable (*nimplex* / *nimplex.exe*) or Python library (*nimplex.so* / *nimplex.pyd*) directly just by placing it in your working directory and using it as:
## 
## 1. An **interactive command line interface (CLI) tool**, which will guide you through how to use it if you run it without any arguments like so (on Linux/MacOS):
##    ```cmd
##    ./nimplex   
##    ```
##    or with a concise configuration defining the task type and parameters (explained later in [Usage in Nim](#usage-in-nim)):
##    ```cmd
##    ./nimplex -c IFP 3 10
##    ```
## 2. An **compiled Python library**, which you can import and use in your Python code like so:
##    ```python
##    import nimplex
##    ```
##    and immediately use the functions provided by the library, as described in [Usage in Python](#usage-in-python):
##    ```python
##    nimplex.simplex_internal_grid_fractional_py(dim=3, ndiv=10)
##    ```
## 
## If the above doesn't work for you, or you want to modify the source code, you can compile the library yourself fairly easily in a couple minutes. 
## The only requirement is to have [Nim](https://nim-lang.org/) installed on your system
## ([Installation Instructions](https://nim-lang.org/install.html)) which can be done on most Linux distributions with a single command:
## ```cmd
## apt-get install nim
## ```
## or on MacOS, assuming you have [Homebrew](https://brew.sh/) installed:
## ```cmd
## brew install nim
## ```
## 
## Then, you can use the boundeled [Nimble](https://github.com/nim-lang/nimble) tool (pip-like package manager for Nim) to install two top-level dependencies: 
## [arraymancer](https://github.com/mratsim/Arraymancer), which is a powerful N-dimensional array library, and [nimpy](https://github.com/yglukhov/nimpy) which 
## helps with the Python bindings. You can do it with a single command:
## ```cmd
## nimble install -y arraymancer nimpy
## ```
## 
## Finally, you can clone the repository and compile the library with:
## ```cmd
## git clone https://github.com/amkrajewski/nimplex
## cd nimplex
## nim c -r -d:release nimplex.nim -benchmark
## ```
## which will compile the library and run a few benchmarks to make sure everything runs smoothly. You should then see a compiled binary file `nimplex` in the current directory which exposes the CLI tool.
## If you want to use the Python bindings, you can compile the library with slightly different flags (depending on your system configuration) like so for Linux/MacOS:
## ```cmd
## nim c --d:release --threads:on --app:lib --out:nimplex.so nimplex
## ```
## and you should see a compiled library file `nimplex.so` in the current directory which can be immediately imported and used in Python.
## 
## 
## ## Capabilities
## ***Note:*** Full technical discussion of methods and motivations is provided in the manuscript. The sections below are meant to provide a concise overview of the library's capabilities.
## 
## The library provides a growing number of methods specific to compositional (simplex) spaces:
## 1. **Monte Carlo sampling** is the simplest method conceptually, where points are rendomly sampled from a simplex. In low dimensional cases, this can be accomplished by sampling from a uniform distribution in 
##     (d-1)-Cartesian space and then rejecting points outside the simplex (left panel below). However, in this approach, the inefficiency growth is **factorial** with the dimensionality of the simplex space. 
##     Instead, some try to sample from a uniform distribution in (d)-Cartesian space and normalize the points to sum to 1, however, this leads to over-sampling in the center of each simplex dimension (middle panel below). 
##     One can, however, fairly easily sample from a special case of Dirichlet distribution, as explained in the manuscript, which leads to uniform sampling in the simplex space (right panel below). **Nimplex can sample 
##     around 10M points per second in 9-dimensional space** on a modern CPU.
##    
##     .. figure:: ../assets/Fig1.png
##        :alt: Random Simplex Sampling
##     
## 2. **Simplex / Compositional Grids** are a more structured approach to sampling, where all possible compositions quantized to a given resolution, like 1% for 100 divisions per dimension, are generated. This is useful for example when
##     one wants to map a function over the simplex space. In total `N_S(d, n_d) = \binom{d-1+n_d}{d-1} = \binom{d-1+n_d}{n_d}` are generated, where `d` is the dimensionality of the simplex space and `n_d` is the number of
##     divisions per dimension. Nimplex uses a modified version of NEXCOM algorithm to do that procedurally (see manuscript for details) and can generate around **2M points per second in 9-dimensional space** on a modern CPU. A choice is given 
##     between generating the gird as a list of **integer** numbers of quantum units (left panel below) or as a list of **fractional positions** (right panel below). 
## 
##     
##     .. figure:: ../assets/Fig2.png
##        :alt: Integer and Fractional Simplex Grids in Ternary Space
## 
## 3. **Internal Simplex / Compositional Grids** are a modification of the above method, where only points inside the simplex, i.e. all components are present, are generated. This is useful in cases where, one cannot discard any component
##     entirely, for instance, because manufacturing setup has minimum feed rate (leakage). Nimplex introduces a new algorithm to generate these points procedurally (see manuscript for details) based on further modification of NEXCOM algorithm.
##     In total `N_I(d, n_d) = \binom{n_d-1}{d-1}` are generated, critically without any performance penalty compared to the full grid, which can reach orders of magnitude when `d` approaches `n_d`. Similar to the full grid, a choice is given
##    between generating the gird as a list of **integer** numbers of quantum units or as a list of **fractional positions**.
## 
## ## Usage in Nim
## Usage within Nim is fairly straightforward. You can install it using Nimble as explained earlier, or install it directly from GitHub:
## ```cmd
## nimble install -y https://github.com/amkrajewski/nimplex
## ```
## or, if you wish to modify the source code, you can simply download the core file `nimplex.nim` and place it in your own code, as long as you have the dependencies installed, since it is standalone. 
## **Then simply follow the API documentation below.**
## 
## ## Usage in Python
## To use the library in Python, you can interact with it just like any other Python library. All input/output types are native Python types, so no additional conversion is necessary. Once you have the library installed and imported,
## **simply follow the API documentation below, with an exception that you need to add `_py` to the function names.** If you happen to forget adding `_py`, the Python interpreter will throw an error with a suggestion to do so.
## 
## ## CLI
## 
## ### Interactive
## Using Nimplex through the CLI relies on the same core library, but provides a simple interface for users who do not want to write any code. It can be used interactively, where the user is guided through the configuration process by 
## just running the executable without any arguments:
## ```cmd
## ./nimplex
## ```
## 
## ### Configured
## Or it can be run with a concise configuration defining the task type and parameters. The configuration is a 3-letter string and 2-3 additional parameters, as explained below.
## - **3-letter configuration**: 
##     1. Grid type or uniform random sampling:
##         - **F**: Full grid (including the simplex boundary)
##         - **I**: Internal grid (only points inside the simplex)
##         - **R**: Random/Monte Carlo uniform sampling over simplex.
##         - **G**: Graph (list of grid nodes and list of their neighbors)
##     2. Fractional or Integer positions:
##         - **F**: Fractional grid/graph (points are normalized to fractions of 1)
##         - **I**: Integer grid/graph (points are integers)
##     3. Print full result, its shape, or persist in a file:
##         - **P**: Print (presents full result as a table)
##         - **S**: Shape (only the shape / size information)
##         - **N**: Persist to NumPy array file ("nimplex_<configFlags>.npy" or 
##              optionally a custom path as an additonal argument)
## - **Simplex Dimensions / N of Components**: An integer number of components in the simplex space.
## - **N Divisions per Dimension / N of Samples**: An integer number of either:
##     1. Divisions per each simplex dimension for grid or graph tasks (F/I/G__)
##     2. Number of samples for random sampling tasks (R__)
## - **(optional) NumPy Array Output Filename**: A custom path to the output NumPy array file (only for __N tasks).
## 
## For instance, to generate a 3-dimensional internal fractional grid with 10 divisions per dimension and persist it to a NumPy array file, you can run:
## ```cmd
## ./nimplex -c IFN 3 10
## ```
## and the output will be saved to `nimplex_IF_3_10.npy` in the current directory. If you want to save it to a different path, you can provide it as an additional argument:
## ```cmd
## ./nimplex -c IFN 3 10 path/to/outfile.npy
## ```
## Or if you want to print the full result to the console, allowing you to pipe it to virtually any other language or tool as plain text, you can run:
## ```cmd
## ./nimplex -c IFP 3 10
## ```
## 


# GRID
proc simplex_grid*(dim: int, 
                   ndiv: int): Tensor[int] =
    # L is the total number of unique points in the simplex grid, which we know a priori
    let L: int = binom(ndiv+dim-1, dim-1)
    result = newTensor[int]([L, dim])
    var x = zeros[int](dim)
    x[dim-1] = ndiv
    for j in 0..dim-1:
        result[0, j] = x[j]
    var h = dim
    for i in 1..L-1:
        h -= 1
        let val = x[h]
        x[h] = 0
        x[dim-1] = val - 1
        x[h-1] += 1
        for j in 0..dim-1:
            result[i, j] = x[j]
        if val != 1:
            h = dim
    return result

proc simplex_grid_fractional*(dim: int,
                              ndiv: int): Tensor[float] =
    result = simplex_grid(dim, ndiv).asType(float)
    result = result.map(x => x / float(ndiv))
    return result

proc simplex_internal_grid*(dim: int, 
                            ndiv: int): Tensor[int] =
    # L is the total number of unique points inside the simplex grid, which we know a priori
    let L: int = binom(ndiv-1, dim-1)
    result = newTensor[int]([L, dim])
    var x = ones[int](dim)
    x[dim-1] = ndiv+1-dim
    for j in 0..dim-1:
        result[0, j] = x[j]
    var h = dim
    for i in 1..L-1:
        h -= 1
        let val = x[h]
        x[h] = 1
        x[dim-1] = val - 1
        x[h-1] += 1
        for j in 0..dim-1:
            result[i, j] = x[j]
        if val != 2:
            h = dim
    return result

proc simplex_internal_grid_fractional*(dim: int,
                                       ndiv: int): Tensor[float] =

    result = simplex_internal_grid(dim, ndiv).asType(float)
    result = result.map(x => x / float(ndiv))
    return result

# RANDOM SAMPLING

proc simplex_sampling_mc(dim: int,
                          samples: int): Tensor[float] =
    let neglograndom = randomTensor[float](
        [samples, dim], 
        1.0
        ).map(x => -ln(x))
    let sums = neglograndom.sum(axis=1)
    result = neglograndom /. sums

# GRAPH

proc simplex_graph_3C*(
    ndiv: int): (Tensor[int], seq[seq[int]]) =

    # L is the total number of unique points in the simplex grid, which we know a priori
    let L: int = binom(ndiv+2, 2)
    var nodes = newTensor[int]([L, 3])
    var neighbors = newSeq[seq[int]](L)
    var x = zeros[int](3)

    func neighborsLink(i:int, x:Tensor, ndiv:int): seq[int] =
        let jump0 = 1
        let jump1 = 1+ndiv-x[0]

        if x[0] != 0:
            result.add(i-jump1)
            result.add(i-jump1-jump0)
        if x[1] != 0:
            result.add(i-jump0)
            result.add(i+jump1-jump0)
        if x[2] != 0:
            result.add(i+jump0)
            result.add(i+jump1)
        return result

    x[2] = ndiv
    for j in 0..2:
        nodes[0, j] = x[j]
    var h = 3

    neighbors[0] = neighborsLink(0, x, ndiv)

    for i in 1..L-1:
        h -= 1
        let val = x[h]
        x[h] = 0
        x[2] = val - 1
        x[h-1] += 1
        for j in 0..2:
            nodes[i, j] = x[j]
        neighbors[i] = neighborsLink(i, x, ndiv)
        if val != 1:
            h = 3
    return (nodes, neighbors)

proc simplex_graph_3C_fractional*(ndiv: int): (Tensor[float], seq[seq[int]]) =
    let graph = simplex_graph_3C(ndiv)
    var nodes = graph[0].asType(float)
    nodes = nodes.map(x => x / float(ndiv))
    return (nodes, graph[1])

proc simplex_graph*(
    dim: int, 
    ndiv: int): (Tensor[int], seq[seq[int]]) =

    # L is the total number of unique points in the simplex grid, which we know a priori
    let L: int = binom(ndiv+dim-1, dim-1)
    var nodes = newTensor[int]([L, dim])
    var neighbors = newSeq[seq[int]](L)
    var x = zeros[int](dim)

    proc neighborsLink(i:int, x:Tensor, ndiv:int, dim:int, 
                       neighbors: var seq[seq[int]]): void =
        var jumps = newSeq[int](dim-1)
        jumps[0] = 1  #binom(x,0)=1
        for j in 1..<(dim-1):
            jumps[j] = binom(j+ndiv-sum(x[0..(dim-2-j)]), j)
        var temp: int
        for order in 0..(dim-2): 
            temp = 0
            if x[order] != 0:
                for dir in 0..(dim-2-order): 
                    temp += jumps[dim-2-order-dir]
                    neighbors[i].add(i - temp)
                    neighbors[i - temp].add(i)

    x[dim-1] = ndiv
    for j in 0..dim-1:
        nodes[0, j] = x[j]
    var h = dim

    neighborsLink(0, x, ndiv, dim, neighbors)

    for i in 1..L-1:
        h -= 1
        let val = x[h]
        x[h] = 0
        x[dim-1] = val - 1
        x[h-1] += 1
        for j in 0..dim-1:
            nodes[i, j] = x[j]
        neighborsLink(i, x, ndiv, dim, neighbors)
        if val != 1:
            h = dim
    return (nodes, neighbors)

proc simplex_graph_fractional*(dim: int, ndiv: int): (Tensor[float], seq[seq[int]]) =
    let graph = simplex_graph(dim, ndiv)
    var nodes = graph[0].asType(float)
    nodes = nodes.map(x => x / float(ndiv))
    return (nodes, graph[1])


# PYTHON BINDINGS
when not defined(nimdoc):

    proc simplex_grid_py*(dim: int, ndiv: int): seq[seq[int]] {.exportpy.} = 
        simplex_grid(dim, ndiv).toSeq2D()

    proc simplex_grid_fractional_py*(dim: int, ndiv: int): seq[seq[float]] {.exportpy.} = 
        simplex_grid_fractional(dim, ndiv).toSeq2D()

    proc simplex_internal_grid_py*(dim: int, ndiv: int): seq[seq[int]] {.exportpy.} = 
        simplex_internal_grid(dim, ndiv).toSeq2D()

    proc simplex_internal_grid_fractional_py*(dim: int, ndiv: int): seq[seq[float]] {.exportpy.} = 
        simplex_internal_grid_fractional(dim, ndiv).toSeq2D()

    proc simplex_sampling_mc_py*(dim: int, samples: int): seq[seq[float]] {.exportpy.} = 
        simplex_sampling_mc(dim, samples).toSeq2D() 

    proc simplex_graph_3C_py*(ndiv: int): (seq[seq[int]], seq[seq[int]]) {.exportpy.} = 
        let graph = simplex_graph_3C(ndiv)
        return (graph[0].toSeq2D(), graph[1])

    proc simplex_graph_3C_fractional_py*(ndiv: int): (seq[seq[float]], seq[seq[int]]) {.exportpy.} =
        let graph = simplex_graph_3C_fractional(ndiv)
        return (graph[0].toSeq2D(), graph[1])

    proc simplex_graph_py*(dim: int, ndiv: int): (seq[seq[int]], seq[seq[int]]) {.exportpy.} = 
        let graph = simplex_graph(dim, ndiv)
        return (graph[0].toSeq2D(), graph[1])

    proc simplex_graph_fractional_py*(dim: int, ndiv: int): (seq[seq[float]], seq[seq[int]]) {.exportpy.} =
        let graph = simplex_graph_fractional(dim, ndiv)
        return (graph[0].toSeq2D(), graph[1])

# UTILS

template benchmark(benchmarkName: string, code: untyped) =
    ## A simple benchmarking template which takes a name and a code block to run. It prints the benchmark name and the duration of the code block execution in natural time units
    ## quantized to microseconds (e.g., 119 milliseconds and 296 microseconds). All tasks together should take 500-1000 milliseconds on a modern CPU.
    block:
        let t0 = cpuTime()
        code
        let t1 = cpuTime()
        echo benchmarkName & "\n" & $initDuration(microseconds = ((t1 - t0)*1e6).int) & "\n"

proc echoHelp*() = 
    ## Prints the help message for the CLI, which is a concise version of one given in nimplex's documentation.
    echo """

To run nimplex please either (1) provide no arguments and follow the prompts or 
(2) use "-c" or "--config" to provide the configuration per instructions below:

- Provide the 3-letter configuration for task type:
    1. Grid type or uniform random sampling:
        - F: Full grid (including the simplex boundary)
        - I: Internal grid (only points inside the simplex)
        - R: Random/Monte Carlo uniform sampling over simplex.
        - G: Graph (list of grid nodes and list of their neighbors)
    2. Fractional or Integer positions:
        - F: Fractional grid/graph (points are normalized to fractions of 1)
        - I: Integer grid/graph (points are integers)
    3. Print full result, its shape, or persist in a file:
        - P: Print (presents full result as a table)
        - S: Shape (only the shape / size information)
        - N: Persist to NumPy array file ("nimplex_<configFlags>.npy" or 
             optionally a custom path as an additonal argument)

- Followed by integers of (1) simplex dimension and (2) number of divisions or
  samples depending on the task type. Optionally, custom output file path for 
  NumPy array can be provided as the last argument. E.g.:
    -c FFS [simplex dimension] [number of divisions]
    -c RFP [simplex dimension] [number of samples]
    -c FIN [simplex dimension] [number of divisions] [path/to/outfile.npy]

You can also utilize the following auxiliary flags:
--help       | -h   --> Show help.
--benchmark  | -b   --> Run benchmark for all tasks (9-dimensional space
                        with 12 divisions per dimension / 1M random samples).
"""

proc configValidation(config: string) = 
    ## Validates the 3-letter configuration string provided by the user.
    assert config.len == 3, "\n--> Invalid configuration lenght. Must be 3 letters."
    assert config[0] in @['F', 'I', 'R', 'G'], "\n--> Invalid configuration (in the 1st letter). Must be F, I or R for Full grid, Internal grid, Monte Carlo sampling, or Graph respectively"
    assert config[1] in @['F', 'I'], "\n--> Invalid configuration (in the 2nd letter). Must be F, or I for Fractional positions, or Integer positions respectively"
    if config[0] == 'R':
        assert config[1] == 'F', "\n--> Integer positions not implemented for Random sampling. Must be F for Fractional positions."
    assert config[2] in @['P', 'S', 'N'], "\n--> Invalid configuration (in the 3rd letter). Must be P, S or N for Print full result, Shape, or persist Numpy output respectively"

proc nDivValidation(config: string, nDiv: int, dim: int) = 
    ## Validates the number of divisions per each simplex dimension provided by the user for all tasks except Random sampling.
    if config[0] == 'I':
        assert ndiv >= dim, "\n--> Invalid number of divisions. Must be greater or equal to the simplex dimension to produce a non-empty internal grid."
    else:
        assert ndiv > 0, "\n--> Invalid number of divisions. Must be a positive integer."

proc outFunction(config: string, dim: int, ndiv: int, npyName: string, outputData: Tensor) =
    ## Handles the output of grid and random sampling tasks when run from the CLI, based on the 3rd letter of the configuration string.
    case config[2]:
        of 'P': echo "Full Output:", outputData
        of 'N': outputData.write_npy(npyName)
        else: discard #return nothing, just print the size
    echo "Full shape:", outputData.shape


proc outFunction_graph(config: string, dim: int, ndiv: int, npyName: string, outputData: (Tensor, seq)) =
    ## Handles the output of graph tasks when run from the CLI, based on the 3rd letter of the configuration string.
    case config[2]:
        of 'P': 
            echo "Nodes:"
            echo outputData[0]
            echo "Neighbors:"
            echo outputData[1]
        of 'N': 
            outputData[0].write_npy(npyName.replace(".npy", "_nodes.npy"))
            let 
                maxNeighbors = dim*(dim-1)
                L = binom(ndiv+dim-1, dim-1)
            var neighborsTensor = newTensor[int]([L, maxNeighbors])
            for i in 0..<L:
                for j in 0..<maxNeighbors:
                    if j < outputData[1][i].len:
                        neighborsTensor[i, j] = outputData[1][i][j]
                    else:
                        neighborsTensor[i, j] = -1
            neighborsTensor.write_npy(npyName.replace(".npy", "_neighbors.npy"))
        else: discard #return nothing, just print the size
    echo "Full shape (nodes):", outputData[0].shape

proc taskRouter(config: string, dim: int, ndiv: int, npyName: string) =
    ## Routes the task to the appropriate calculation and output function based on the first 2 letters of the configuration string.
    case config[0..1]:
        of "FF": outFunction(config, dim, ndiv, npyName, 
                             simplex_grid_fractional(dim, ndiv))
        of "FI": outFunction(config, dim, ndiv, npyName, 
                             simplex_grid(dim, ndiv))
        of "IF": outFunction(config, dim, ndiv, npyName, 
                             simplex_internal_grid_fractional(dim, ndiv))
        of "II": outFunction(config, dim, ndiv, npyName, 
                             simplex_internal_grid(dim, ndiv))
        of "RF": outFunction(config, dim, ndiv, npyName, 
                             simplex_sampling_mc(dim, samples=ndiv))
        of "GI": outFunction_graph(config, dim, ndiv, npyName, 
                                   simplex_graph(dim, ndiv))
        of "GF": outFunction_graph(config, dim, ndiv, npyName, 
                                   simplex_graph_fractional(dim, ndiv))
        else:
            echo "\n--> Invalid configuration in the first 2 config letters."
            quit(1)

when appType != "lib":
    when isMainModule:
        let args = commandLineParams() ## \
        ## Command line arguments parsed when the module is run as a script, rather than as a library, allowing efortless CLI usage without any Python or Nim knowledge.
        ## When empty, interactive mode is triggered and user is navigated through the configuration process. Otherwise, the first argument is expected to be `-c` or `--config` 
        ## followed by the configuration flags and parameters as described in the help message below. See `echoHelp()` for more details.
        
        # Interactive
        if args.len == 0:
            echo "Configuration (Full/Internal/Random/Graph)(Fractional/Integer)(Print/Shape/Numpysave) - e.g. FFS/RFP/FIN:"
            let config = readLine(stdin)
            configValidation(config)

            echo "Simplex Dimensions / N of Components:"
            let dim = readLine(stdin).parseInt() 

            var nDiv: int
            if config[0]=='R':
                echo "Number of Samples:"
                nDiv = readLine(stdin).parseInt()
                assert nDiv > 0, "\n--> Invalid number of samples. Must be a positive integer"
            else:
                echo "N Divisions per Dimension:"
                ndiv = readLine(stdin).parseInt() 
                nDivValidation(config, ndiv, dim)

            var npyName: string = "nimplex_" & config[0..1] & "_" & $dim & "_" & $ndiv & ".npy"
            if config[2] == 'N':
                echo "NumPy Array Output Filename (skip for default: " & npyName & "):"
                let tempIn = readLine(stdin)
                if tempIn.len > 0:
                    npyName = tempIn
                echo "Persisting to NumPy array file:", npyName

            taskRouter(config, dim, ndiv, npyName)

        # Configured
        elif args[0] == "-c" or args[0] == "--config":
            let config = args[1]
            echo "Running with configuration:", args[1..<args.len]
            configValidation(config)

            let dim = args[2].parseInt()
            assert dim > 0, "Invalid dimension"

            var nDiv: int
            if config[0]=='R':
                nDiv = args[3].parseInt()
                assert nDiv > 0, "\n--> Invalid sample number. Must be a positive integer"
            else:
                ndiv = args[3].parseInt()
                nDivValidation(config, ndiv, dim)

            var npyName: string = "nimplex_" & config[0..1] & "_" & $dim & "_" & $ndiv & ".npy"
            if config[2] == 'N':
                if args.len == 5:
                    npyName = args[4]
                echo "Persisting to NumPy array file:", npyName

            taskRouter(config, dim, ndiv, npyName)

        elif args[0] in @["-h", "--help"]:
            echoHelp()
            quit(0)

        elif args[0] in @["-b", "--benchmark"]:
            # A few benchmarks for the library to compare across different systems, implementations, and languages.
            benchmark "Simplex Grid Full (dim=9, ndiv=12):":
                discard simplex_grid(9, 12)
            benchmark "Simplex Grid Internal (dim=9, ndiv=12):":
                discard simplex_internal_grid(9, 12)
            benchmark "Simplex Random Sampling (dim=9, samples=1M):":
                discard simplex_sampling_mc(9, 1_000_000)
            benchmark "Simplex Graph (dim=9, ndiv=12):":
                discard simplex_graph(9, 12)
            benchmark "Simplex Graph ND (dim=3, ndiv=1000):":
                discard simplex_graph(3, 1000)
            benchmark "Simplex Graph 3D (dim=3, ndiv=1000):":
                discard simplex_graph_3C(1000)

        # Fallback
        else:
            echoHelp()
            quit(1)