#define PY_SSIZE_T_CLEAN
#include <Python.h>

PyObject* paste_as(PyObject *, PyObject *);

static struct PyMethodDef methods[] = {
    {"paste_as", (PyCFunction)paste_as, METH_VARARGS, "Fetch current pasteboard data."},
    {NULL, NULL, 0, NULL}  /* Sentinel */
};

static struct PyModuleDef module = {
    PyModuleDef_HEAD_INIT,
    "pyclip",
    NULL,
    -1,
    methods
};

PyMODINIT_FUNC PyInit_pyclip(void) {
    return PyModule_Create(&module);
}
