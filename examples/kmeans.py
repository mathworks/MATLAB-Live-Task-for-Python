# Data conversion
import numpy as np
data = np.array(data)

# Using Scikit-learn
from sklearn.cluster import KMeans as scikit_kmeans
kmeans_scikit_res = scikit_kmeans(n_clusters=nclust,init='k-means++').fit(data)
scikit_centroids = kmeans_scikit_res.cluster_centers_

# Using Scipy
import scipy.cluster
scipy_res = scipy.cluster.vq.kmeans2(data,k=nclust,minit='++')
scipy_centroids = scipy_res[0]