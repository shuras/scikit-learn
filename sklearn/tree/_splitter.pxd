# cython: language_level=3

# Authors: Gilles Louppe <g.louppe@gmail.com>
#          Peter Prettenhofer <peter.prettenhofer@gmail.com>
#          Brian Holt <bdholt1@gmail.com>
#          Joel Nothman <joel.nothman@gmail.com>
#          Arnaud Joly <arnaud.v.joly@gmail.com>
#          Jacob Schreiber <jmschreiber91@gmail.com>
#
# License: BSD 3 clause

# See _splitter.pyx for details.

import numpy as np
cimport numpy as np

from ._utils cimport SplitValue, SplitRecord, BITSET_t

from ._criterion cimport Criterion

ctypedef np.npy_float32 DTYPE_t          # Type of X
ctypedef np.npy_float64 DOUBLE_t         # Type of y, sample_weight
ctypedef np.npy_intp SIZE_t              # Type for indices and counters
ctypedef np.npy_int32 INT32_t            # Signed 32 bit integer
ctypedef np.npy_uint32 UINT32_t          # Unsigned 32 bit integer
ctypedef np.npy_uint64 UINT64_t          # Unsigned 64 bit integer

cdef class Splitter:
    # The splitter searches in the input space for a feature and a threshold
    # to split the samples samples[start:end].
    #
    # The impurity computations are delegated to a criterion object.

    # Internal structures
    cdef public Criterion criterion      # Impurity criterion
    cdef public SIZE_t max_features      # Number of features to test
    cdef public SIZE_t min_samples_leaf  # Min samples in a leaf
    cdef public double min_weight_leaf   # Minimum weight in a leaf

    cdef object random_state             # Random state
    cdef UINT32_t rand_r_state           # sklearn_rand_r random number state

    cdef SIZE_t* samples                 # Sample indices in X, y
    cdef SIZE_t n_samples                # X.shape[0]
    cdef double weighted_n_samples       # Weighted number of samples
    cdef SIZE_t* features                # Feature indices in X
    cdef SIZE_t* constant_features       # Constant features indices
    cdef SIZE_t n_features               # X.shape[1]
    cdef DTYPE_t* feature_values         # temp. array holding feature values

    cdef SIZE_t start                    # Start position for the current node
    cdef SIZE_t end                      # End position for the current node

    cdef bint presort                    # Whether to use presorting, only
                                         # allowed on dense data
    cdef bint breiman_shortcut           # Whether decision trees are allowed to use the
                                         # Breiman shortcut for categorical features

    cdef DOUBLE_t* y
    cdef SIZE_t y_stride
    cdef DOUBLE_t* sample_weight
    cdef INT32_t[:] n_categories         # (n_features,) array giving number of
                                         # categories (<0 for non-categorical)
    cdef BITSET_t* cat_cache             # Cache buffer for fast categorical split evaluation

    # The samples vector `samples` is maintained by the Splitter object such
    # that the samples contained in a node are contiguous. With this setting,
    # `node_split` reorganizes the node samples `samples[start:end]` in two
    # subsets `samples[start:pos]` and `samples[pos:end]`.

    # The 1-d  `features` array of size n_features contains the features
    # indices and allows fast sampling without replacement of features.

    # The 1-d `constant_features` array of size n_features holds in
    # `constant_features[:n_constant_features]` the feature ids with
    # constant values for all the samples that reached a specific node.
    # The value `n_constant_features` is given by the parent node to its
    # child nodes.  The content of the range `[n_constant_features:]` is left
    # undefined, but preallocated for performance reasons
    # This allows optimization with depth-based tree building.

    # Methods
    cdef int init(self, object X, np.ndarray y,
                  DOUBLE_t* sample_weight,
                  INT32_t[:] n_categories,
                  np.ndarray X_idx_sorted=*) except -1

    cdef int node_reset(self, SIZE_t start, SIZE_t end,
                        double* weighted_n_node_samples) nogil except -1

    cdef int node_split(self,
                        double impurity,   # Impurity of the node
                        SplitRecord* split,
                        SIZE_t* n_constant_features) nogil except -1

    cdef void node_value(self, double* dest) nogil

    cdef double node_impurity(self) nogil
