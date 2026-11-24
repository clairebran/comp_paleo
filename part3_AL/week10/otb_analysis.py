# %% Setup
import numpy as np
import pandas as pd
print(np.__version__, pd.__version__)

# %% Part 1 — language basics
squared = [x**2 for x in range(10)]
print(squared)

# %% [markdown]
# ## Why virtual environments matter
#
# Without isolation, installing Flask for one project can silently break
# another. A virtual environment confines every `pip install` to a single
# project directory.abs

# %% 5 language features 
import pandas as pd

# 1. List comprehension: convert molar lengths to cm, keeping only those over 12 mm
molar_lengths_mm = [10.8, 12.4, 14.1, 11.9, 13.6, 15.2]
large_molars_cm = [round(length / 10, 2) for length in molar_lengths_mm if length > 12]
print(large_molars_cm)

# 2. Dictionary comprehension: count identified elements per bovid genus
bovid_finds = {
    'Tragelaphus': ['horn core', 'molar', 'phalanx'],
    'Kobus': ['mandible', 'molar'],
    'Alcelaphini': ['horn core', 'astragalus', 'molar', 'metacarpal'],
}
element_counts = {genus: len(elements) for genus, elements in bovid_finds.items()}
print(element_counts)

# 3. zip and enumerate: pair sample IDs with enamel carbon isotope values
sample_ids = ['ENM-01', 'ENM-02', 'ENM-03', 'ENM-04']
d13c_values = [-9.2, -1.5, -3.8, -10.1]
for i, (sample, d13c) in enumerate(zip(sample_ids, d13c_values), start=1):
    print(f"{i}. {sample}: d13C = {d13c} per mil")

# 4. *args and **kwargs: log a find with any number of elements and any extra metadata
def log_find(site, *elements, **context):
    print(f"{site}: {len(elements)} elements ({', '.join(elements)})")
    for key, value in context.items():
        print(f"   {key}: {value}")

log_find('Locality 12', 'rib', 'tooth', 'scapula',
         stratum='Member B', weathering_stage=2, excavator='field crew 3')

# 5. Lambda with apply: classify bones by Behrensmeyer weathering stage
finds = pd.DataFrame({
    'find_id': ['F-101', 'F-102', 'F-103', 'F-104'],
    'element': ['femur', 'rib', 'mandible', 'vertebra'],
    'weathering_stage': [0, 2, 4, 1],
})
finds['surface_condition'] = finds['weathering_stage'].apply(
    lambda stage: 'minimal weathering' if stage <= 1 else 'advanced weathering'
)
print(finds)

# %% [markdown]
# # Part 2: NumPy

# %% 2.1 1-D array of stratigraphic ages
import numpy as np

ages_ma = np.array([2.58, 2.35, 2.10, 1.95, 1.87, 1.78,
                    1.65, 1.52, 1.44, 1.30, 1.18, 1.07])

print(ages_ma.dtype)   # float64
print(ages_ma.shape)   # (12,)
print(ages_ma.ndim)    # 1

# Vectorized conversion: Ma -> ka (1 Ma = 1000 ka)
ages_ka = ages_ma * 1000
print(ages_ka)

# %% 2.2 2-D array: 6 specimens x 3 measurements (all in mm)
# columns: molar length, molar breadth, crown height
molars = np.array([
    [14.2, 11.1,  9.8],
    [12.9, 10.4,  8.7],
    [15.6, 12.3, 10.9],
    [13.4, 10.8,  9.1],
    [16.1, 12.9, 11.4],
    [12.2,  9.9,  8.2],
])
print(molars.shape)            # (6, 3)

# Slicing
print(molars[2, :])            # one specimen (row), all measurements
print(molars[:, 1])            # one measurement (column), all specimens

# Column-wise means (one mean per measurement)
print(molars.mean(axis=0))     # shape (3,)

# Row-wise standard deviation (one value per specimen)
print(molars.std(axis=1))      # shape (6,)

# %% 2.3 Indexing the age array
# Boolean indexing: specimens in a time window (1.5-2.0 Ma)
window = ages_ma[(ages_ma > 1.5) & (ages_ma < 2.0)]
print(window)

# Fancy indexing: exactly three specimens by position
idx = np.array([0, 5, 11])
print(ages_ma[idx])

# Compound condition: the oldest OR youngest specimens (outside 1.3-2.3 Ma)
extremes = ages_ma[(ages_ma < 1.3) | (ages_ma > 2.3)]
print(extremes)

# %% [markdown]
# ## Why vectorization is faster, and when loops are still needed
# NumPy stores values of one type in a contiguous block of memory and runs
# operations over that block in compiled C code. A Python loop has to check
# types and run interpreter overhead on every single element, which is
# where the big speed difference comes from. I would still write a loop
# when each step depends on the result of the previous one (like a running
# calculation where step n needs step n-1), or when the work per item is
# complicated branching logic that can't be expressed as array operations.

