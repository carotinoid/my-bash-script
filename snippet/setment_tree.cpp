template <typename T, T(*op)(T, T), T I>
struct Segtree {

    // Variables
    T *arr;
    int arr_size, seg_size;
    T *seg;

    // Constructor
    Segtree(int s, T *a = NULL) {
        arr = a; arr_size = s;
        seg_size = arr_size * 4 + 1;
        seg = new T[seg_size];
        build(1, 1, arr_size);
    }
    T build(int node_index, int left, int right) {
        if(left == right) {
            return seg[node_index] = arr?arr[left]:I;
        }
        int mid = (left + right) / 2;
        T l = build(node_index * 2, left, mid);
        T r = build(node_index * 2 + 1, mid+1, right);
        return seg[node_index] = op(l, r);
    }

    // Destructor
    ~Segtree() {delete[] seg;}

    // Features
    T _get(int st, int en, int node_index, int left, int right) {
        if(en < left or right < st) return T(I);
        if(st <= left and right <= en) return seg[node_index];
        int mid = (left + right) / 2;
        T l = _get(st, en, node_index * 2, left, mid);
        T r = _get(st, en, node_index * 2 + 1, mid+1, right);
        return op(l, r);
    }
    T _update(int pos, T v, int node_index, int left, int right) {
        if(pos < left or right < pos) return seg[node_index];
        if(left == right and left == pos) {
            arr[pos] = v;
            return seg[node_index] = v;
        }
        int mid = (left + right) / 2;
        T l = _update(pos, v, node_index * 2, left, mid);
        T r = _update(pos, v, node_index * 2 + 1, mid+1, right);
        return seg[node_index] = op(l, r);
    }

    // Interfaces
    void update(int pos, T val) {
        _update(pos, val, 1, 1, arr_size);
    }
    T get(int st, int en) {
        return _get(st, en, 1, 1, arr_size);
    }
};
using Seg = Segtree<ll, [](ll a, ll b){return a + b;}, 0LL>;