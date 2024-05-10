class QuickSort {
  List<int> sort(List<int> arr, int low, int high) {
    if (low < high) {
      int pivotIndex = _partition(arr, low, high);
      sort(arr, low, pivotIndex - 1);
      sort(arr, pivotIndex + 1, high);
    }
    return arr;
  }

  int _partition(List<int> arr, int low, int high) {
    int pivot = arr[high];
    int i = low - 1;

    for (int j = low; j < high; j++) {
      if (arr[j] < pivot) {
        i++;
        _swap(arr, i, j);
      }
    }

    _swap(arr, i + 1, high);
    return i + 1;
  }

  void _swap(List<int> arr, int i, int j) {
    int temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
  }
}
