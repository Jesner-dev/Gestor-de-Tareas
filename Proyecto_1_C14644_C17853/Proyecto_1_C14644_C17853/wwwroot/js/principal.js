// Esperar a que el DOM esté completamente cargado
document.addEventListener("DOMContentLoaded", () => {
    // Obtener elementos del DOM
    const botonAbrirModal = document.getElementById("openModalBtn");
    const modalTareaElemento = document.getElementById("taskModal");
    const modalEditarTarea = document.getElementById("editTaskModal");
    const modalConfirmacion = document.getElementById("modalConfirmacion");

    // Verificar si los elementos existen antes de agregar eventos
    if (botonAbrirModal && modalTareaElemento) {
        // Mostrar el modal al hacer clic en el botón
        botonAbrirModal.addEventListener("click", () => {
            modalTareaElemento.classList.remove('hidden');
            modalTareaElemento.classList.add('flex');
        });

        // Cargar usuarios cuando se muestra el modal
        modalTareaElemento.addEventListener('click', async (e) => {
            if (e.target === modalTareaElemento || e.target.classList.contains('btn-close')) {
                modalTareaElemento.classList.add('hidden');
                modalTareaElemento.classList.remove('flex');
            }
            await cargarUsuarios();
        });
    }

    // Configurar Drag and Drop para actualizar el estado de la tarea
    const columnas = document.querySelectorAll('.column');
    columnas.forEach(columna => {
        // Permitir el arrastre sobre las columnas
        columna.addEventListener('dragover', e => {
            e.preventDefault();
            e.dataTransfer.dropEffect = "move";
            columna.classList.add('bg-gray-700');
        });

        columna.addEventListener('dragleave', () => {
            columna.classList.remove('bg-gray-700');
        });

        // Manejar el evento de soltar para actualizar el estado de la tarea
        columna.addEventListener('drop', async e => {
            e.preventDefault();
            columna.classList.remove('bg-gray-700');
            const idTarea = e.dataTransfer.getData('taskId');

            if (!idTarea || idTarea === "0") {
                console.error("ID de tarea no válido en el evento drop:", idTarea);
                return;
            }

            const tarea = document.querySelector(`[data-id="${idTarea}"]`);

            if (tarea && columna.id) {
                columna.appendChild(tarea);
                await actualizarTareaEstado(idTarea, columna.id);
                location.reload();
            }
        });
    });

    // Configurar eventos de arrastre para las tarjetas de tareas
    document.querySelectorAll('.card').forEach(tarea => {
        tarea.addEventListener('dragstart', e => {
            tarea.classList.add('opacity-50', 'border-2', 'border-blue-500');
            const idTarea = tarea.dataset.id;

            if (!idTarea || idTarea === "0") {
                console.error("Error: Tarea sin ID válido al iniciar drag.", tarea);
                return;
            }

            console.log(`Iniciando drag con ID de tarea: ${idTarea}`);
            e.dataTransfer.setData('taskId', idTarea);
            e.dataTransfer.effectAllowed = "move";
        });

        tarea.addEventListener('dragend', () => {
            tarea.classList.remove('opacity-50', 'border-2', 'border-blue-500');
        });
    });

    // Asociar eventos al cargar la página
    const editTaskForm = document.getElementById("editTaskForm");
    if (editTaskForm) {
        editTaskForm.addEventListener("submit", actualizarTarea);
    }

    // Configurar el botón de confirmar eliminación
    const confirmarEliminarBtn = document.getElementById('confirmarEliminar');
    const cerrarModalBtns = [
        document.getElementById('cerrarModalConfirmar'),
        document.getElementById('cerrarConIcono')
    ];

    if (confirmarEliminarBtn) {
        confirmarEliminarBtn.addEventListener('click', async () => {
            if (tareaIdAEliminar !== null) {
                await eliminarTarea(tareaIdAEliminar);
                modalConfirmacion.classList.add('hidden');
                modalConfirmacion.classList.remove('flex');
            }
        });
    }

    cerrarModalBtns.forEach(btn => {
        if (btn) {
            btn.addEventListener('click', () => {
                modalConfirmacion.classList.add('hidden');
                modalConfirmacion.classList.remove('flex');
            });
        }
    });

    // Cerrar modales al hacer clic fuera del contenido
    [modalTareaElemento, modalEditarTarea, modalConfirmacion].forEach(modal => {
        if (modal) {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    modal.classList.add('hidden');
                    modal.classList.remove('flex');
                }
            });
        }
    });
});

// Función para mostrar el spinner
const mostrarSpinner = () => {
    const spinner = document.getElementById("spinner");
    if (spinner) {
        spinner.classList.remove('hidden');
        spinner.classList.add('flex');
    }
}

// Función para ocultar el spinner
const ocultarSpinner = () => {
    const spinner = document.getElementById("spinner");
    if (spinner) {
        spinner.classList.add('hidden');
        spinner.classList.remove('flex');
    }
}

// Función para mostrar una alerta de éxito
const mostrarAlerta = (mensaje) => {
    const alertBox = document.getElementById('alertBox');
    const alertMessage = document.getElementById('alertMessage');

    if (alertBox && alertMessage) {
        alertMessage.textContent = mensaje;
        alertBox.classList.remove('hidden');
        alertBox.classList.add('flex');

        setTimeout(() => {
            alertBox.classList.add('hidden');
            alertBox.classList.remove('flex');
            location.reload();
        }, 1000);
    }
}

// Función para mostrar una alerta de error
const mostrarAlertaError = (mensaje) => {
    const alertBox = document.getElementById('alertBoxDanger');
    const alertMessage = document.getElementById('alertMessageDanger');

    if (alertBox && alertMessage) {
        alertMessage.textContent = mensaje;
        alertBox.classList.remove('hidden');
        alertBox.classList.add('flex');

        setTimeout(() => {
            alertBox.classList.add('hidden');
            alertBox.classList.remove('flex');
            location.reload();
        }, 2000);
    }
}

// Función para actualizar el estado de una tarea al moverla de columna
const actualizarTareaEstado = async (idTarea, estado) => {
    try {
        const numero = parseInt(idTarea);
        const tarea = {
            Id_Tarea: numero,
            Estado: estado
        };
        mostrarSpinner();
        const response = await fetch('/Main/ActualizarEstadoTarea', {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(tarea)
        });

        if (!response.ok) {
            throw new Error(`Error al actualizar la tarea: ${response.status}`);
        }
    } catch (error) {
        console.error('Error al actualizar la tarea:', error);
        mostrarAlertaError('Error al actualizar el estado de la tarea');
    } finally {
        ocultarSpinner();
    }
}

let usuariosSeleccionados = new Set();

const llenarUsuariosAsignados = (usuarios) => {
    const contenedorUsuarios = document.getElementById("AssignedTo");
    contenedorUsuarios.innerHTML = "";

    usuarios.forEach(usuario => {
        const div = document.createElement("div");
        div.className = "flex items-center p-2 hover:bg-gray-600 rounded";

        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.className = "w-4 h-4 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500";
        checkbox.name = "AssignedTo"; // Nombre igual que el parámetro del controlador
        checkbox.value = usuario.id_Usuario;
        checkbox.checked = usuariosSeleccionados.has(usuario.id_Usuario.toString());

        checkbox.addEventListener('change', (e) => {
            if (e.target.checked) {
                usuariosSeleccionados.add(usuario.id_Usuario.toString());
            } else {
                usuariosSeleccionados.delete(usuario.id_Usuario.toString());
            }
        });

        const label = document.createElement("label");
        label.className = "ml-2 text-sm text-gray-300 cursor-pointer";
        label.textContent = usuario.nombre;

        div.appendChild(checkbox);
        div.appendChild(label);
        contenedorUsuarios.appendChild(div);
    });
};

// Modificación en el event listener del formulario
document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("createTaskForm");
    if (form) {
        form.addEventListener("submit", function (e) {
            // Asegurarse de que los checkboxes seleccionados se envíen
            usuariosSeleccionados.forEach(userId => {
                const hiddenInput = document.createElement("input");
                hiddenInput.type = "hidden";
                hiddenInput.name = "AssignedTo";
                hiddenInput.value = userId;
                this.appendChild(hiddenInput);
            });

            // Continuar con el envío normal
            return true;
        });
    }

    // Configuración del modal
    const modal = document.getElementById("taskModal");
    if (modal) {
        modal.addEventListener("shown.bs.modal", cargarUsuarios);
        modal.addEventListener("hidden.bs.modal", () => {
            usuariosSeleccionados.clear();
        });
    }
});

const cargarUsuarios = async () => {
    const contenedorUsuarios = document.getElementById("AssignedTo");
    if (!contenedorUsuarios) return;

    try {
        const response = await fetch("/User/ObtenerUsuarios");
        if (!response.ok) throw new Error('Error al cargar usuarios');
        const usuarios = await response.json();
        llenarUsuariosAsignados(usuarios);
    } catch (error) {
        console.error(error);
    }
};

// Al cerrar el modal
document.getElementById("taskModal")?.addEventListener("hidden.bs.modal", () => {
    usuariosSeleccionados.clear();
});

let tareaIdAEliminar = null;

// Función para abrir el modal de confirmación
const abrirModalConfirmacion = (id) => {
    tareaIdAEliminar = id;
    const modalConfirmacion = document.getElementById('modalConfirmacion');
    if (modalConfirmacion) {
        modalConfirmacion.classList.remove('hidden');
        modalConfirmacion.classList.add('flex');
    }
}

// Función para eliminar una tarea
const eliminarTarea = async (id) => {
    try {
        mostrarSpinner();
        const response = await fetch(`/Main/EliminarTarea/${id}`, {
            method: 'DELETE',
            headers: { 'Content-Type': 'application/json' }
        });

        if (response.ok) {
            const data = await response.json();
            mostrarAlerta('Tarea eliminada correctamente.');
            if (data.redirectUrl) {
                window.location.href = data.redirectUrl;
            } else {
                location.reload();
            }
        } else if (response.status === 404) {
            mostrarAlertaError('La tarea no fue encontrada.');
        } else if (response.status === 500) {
            mostrarAlertaError('Error interno del servidor al eliminar la tarea.');
        } else {
            mostrarAlertaError(`Error desconocido: ${response.status}`);
        }
    } catch (error) {
        console.error('Error al eliminar la tarea:', error);
        mostrarAlertaError('Ocurrió un error al intentar eliminar la tarea.');
    } finally {
        ocultarSpinner();
    }
}

// Obtener todos los usuarios
const obtenerUsuariosCompletos = async () => {
    mostrarSpinner();
    const response = await fetch("/User/ObtenerUsuarios");

    if (!response.ok) {
        throw new Error(`Error en la respuesta: ${response.status} ${response.statusText}`);
    }
    const usuarios = await response.json();
    return usuarios;
}

// Función para editar una tarea (con Tailwind)
const editarTarea = async (tarea) => {
    document.getElementById("editTaskId").value = tarea.id_Tarea;
    document.getElementById("editTitle").value = tarea.titulo;
    document.getElementById("editDescription").value = tarea.descripcion;
    document.getElementById("editDueDate").value = tarea.fechaVencimiento ? tarea.fechaVencimiento.split("T")[0] : "";
    document.getElementById("editPriority").value = tarea.prioridad;
    document.getElementById("editEstado").value = tarea.estado;

    // Obtener todos los usuarios
    try {
        const todosUsuarios = await obtenerUsuariosCompletos();
        const assignedToDiv = document.getElementById("editAssignedTo");
        assignedToDiv.innerHTML = "";

        todosUsuarios.forEach(usuario => {
            const estaAsignado = tarea.usuariosAsignados?.some(asignado => asignado.id_Usuario === usuario.id_Usuario);

            const checkbox = document.createElement("div");
            checkbox.className = "flex items-center mb-2";
            checkbox.innerHTML = `
                <input class="w-4 h-4 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500" 
                       type="checkbox" name="AssignedTo[]" value="${usuario.id_Usuario}" 
                       id="user-${usuario.id_Usuario}" ${estaAsignado ? "checked" : ""}>
                <label class="ms-2 text-sm font-medium text-gray-300" for="user-${usuario.id_Usuario}">
                    ${usuario.nombre}
                </label>
            `;
            assignedToDiv.appendChild(checkbox);
        });
    } catch (error) {
        console.error("Error al obtener usuarios:", error);
        mostrarAlertaError('Error al cargar usuarios para asignación');
    } finally {
        ocultarSpinner();
    }

    // Mostrar el modal de edición
    const modalElement = document.getElementById("editTaskModal");
    if (modalElement) {
        modalElement.classList.remove('hidden');
        modalElement.classList.add('flex');
    } else {
        console.error("El modal no fue encontrado en el DOM");
    }
};

// Enviar la actualización al servidor
const enviarActualizacion = async (formData) => {
    return await fetch("/Main/actualizarTarea", {
        method: "POST",
        body: formData
    });
};

// Función para actualizar la tarea
const actualizarTarea = async (event) => {
    event.preventDefault();
    const formData = obtenerDatosFormulario();

    try {
        mostrarSpinner();
        const response = await enviarActualizacion(formData);
        const result = await response.json();

        if (response.ok) {
            mostrarAlerta("Tarea actualizada correctamente");
            location.reload();
        } else {
            mostrarError(result.errors || ["Error al actualizar la tarea"]);
        }
    } catch (error) {
        console.error("Error en la actualización:", error);
        mostrarError(["Error al actualizar la tarea."]);
    } finally {
        ocultarSpinner();
    }
};

// Obtener datos del formulario
const obtenerDatosFormulario = () => {
    const form = document.getElementById("editTaskForm");
    const formData = new FormData(form);

    // Obtener los usuarios asignados
    document.querySelectorAll("input[name='AssignedTo[]']:checked").forEach(checkbox => {
        formData.append("AssignedTo", checkbox.value);
    });

    // Obtener los usuarios no asignados
    document.querySelectorAll("input[name='AssignedTo[]']:not(:checked)").forEach(checkbox => {
        formData.append("NoAssignedTo", checkbox.value);
    });

    return formData;
};

// Mostrar errores en el formulario
const mostrarError = (errores) => {
    const errorElement = document.getElementById("editTaskError");
    if (errorElement) {
        errorElement.textContent = errores.join(", ");
        errorElement.classList.remove('hidden');
    }
};
