# Sistema de Paletas de Colores - DeLirio App

## 🎨 **Nueva Funcionalidad Implementada**

Se ha añadido un sistema completo de selección de paletas de colores que permite a los usuarios personalizar la apariencia de la aplicación manteniendo el mismo diseño elegante.

## 🌈 **Paletas Disponibles**

### 1. **Rosa (Original DeLirio)**
- **Color Primario**: Rosa intenso (#E35A83)
- **Color Secundario**: Verde hoja (#8CBF88) 
- **Color de Acento**: Rosa pálido (#F7C7D9)
- **Fondo**: Crema (#FFF6F2)

### 2. **Verde (Natura)**
- **Color Primario**: Verde (#4CAF50)
- **Color Secundario**: Verde lima (#81C784)
- **Color de Acento**: Verde claro (#C8E6C9)
- **Fondo**: Verde muy suave (#F1F8E9)

### 3. **Azul (Océano)**
- **Color Primario**: Azul (#2196F3)
- **Color Secundario**: Azul claro (#64B5F6)
- **Color de Acento**: Azul muy claro (#BBDEFB)
- **Fondo**: Azul muy suave (#E3F2FD)

## 🚀 **Cómo Usar**

### **Acceder al Selector de Paletas**

1. Ve a la pantalla de **Perfil**
2. En la sección **Preferencias**, encontrarás dos opciones:
   - **Tema**: Para cambiar entre claro/oscuro/sistema
   - **Paleta de colores**: Para seleccionar entre Rosa/Verde/Azul

### **Cambiar Paleta**

1. Toca en **"Paleta de colores"**
2. Se abrirá un selector con las 3 opciones
3. Cada opción muestra:
   - **Muestra visual** con gradiente de colores
   - **Nombre** de la paleta
   - **Descripción** breve
4. Selecciona tu paleta favorita
5. El cambio se aplica **inmediatamente**

## 🌙 **Modo Oscuro Adaptativo**

Cada paleta incluye una versión optimizada para modo oscuro:

- **Fondos oscuros** (#121212 y #1D1D1D) para mejor experiencia nocturna
- **Colores primarios** mantenidos para consistencia de marca
- **Contraste optimizado** para legibilidad
- **Iconos y texto** en blanco para mejor visibilidad

## 💡 **Características Técnicas**

### **Cambio Instantáneo**
- Los cambios se aplican inmediatamente sin necesidad de reiniciar
- Animaciones suaves entre transiciones
- Persistencia de selección durante la sesión

### **Adaptación Automática**
- Los componentes se adaptan automáticamente a la nueva paleta
- Botones, campos de texto, cards y navegación cambian coherentemente
- AppBar y elementos de navegación siguen la paleta seleccionada

### **Modo Sistema**
- Respeta la configuración del dispositivo (claro/oscuro)
- Combina automáticamente con la paleta seleccionada
- Cambia automáticamente según la hora del día si está configurado en el dispositivo

## 🎯 **Beneficios para el Usuario**

### **Personalización**
- Cada usuario puede elegir los colores que más le gusten
- Opción de cambiar según el estado de ánimo o preferencias
- Experiencia única y personalizada

### **Accesibilidad**
- Todas las paletas cumplen con estándares de contraste WCAG
- Mejor legibilidad en diferentes condiciones de iluminación
- Opciones para preferencias visuales diversas

### **Usabilidad**
- Interfaz intuitiva para cambio de paletas
- Vista previa inmediata de los colores
- Selector visual fácil de entender

## 🔧 **Implementación Técnica**

### **Archivos Modificados**
- `lib/theme.dart` - Sistema de paletas y temas
- `lib/main.dart` - Integración de temas dinámicos  
- `lib/screens/profile_screen.dart` - Interfaz de selección

### **Componentes Nuevos**
- `ColorPalette enum` - Enumeración de paletas disponibles
- `_getColorsForPalette()` - Función para obtener colores por paleta
- `_ColorPaletteOption` - Widget para mostrar opciones de paleta
- `showColorPalettePicker()` - Selector modal de paletas

### **Controller Mejorado**
- `ThemeController.palette` - Propiedad para paleta actual
- `ThemeController.setPalette()` - Método para cambiar paleta
- `ThemeController.paletteDisplayName` - Nombre para mostrar

## 📱 **Pruebas Recomendadas**

1. **Cambio entre paletas** en modo claro
2. **Cambio entre paletas** en modo oscuro  
3. **Transición automática** con modo sistema
4. **Persistencia** al navegar entre pantallas
5. **Adaptación de todos los componentes** (botones, cards, etc.)

## 🎉 **Resultado Final**

Los usuarios ahora pueden:
- ✅ Elegir entre 3 paletas de colores hermosas
- ✅ Cambiar fácilmente desde la pantalla de perfil
- ✅ Disfrutar de modo oscuro en todas las paletas
- ✅ Ver cambios instantáneos y suaves
- ✅ Mantener una experiencia visual consistente

La aplicación mantiene su diseño elegante mientras ofrece opciones de personalización que se adaptan a diferentes gustos y preferencias visuales.