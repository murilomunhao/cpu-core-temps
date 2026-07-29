# CPU Core Temps

**Widget para a barra de tarefas do KDE Plasma 6**

Temperaturas dos **núcleos físicos** da CPU em texto colorido — direto no painel.

[![Plasma 6](https://img.shields.io/badge/Plasma-6-blue?style=flat-square)](https://kde.org/plasma-desktop/)
[![Site](https://img.shields.io/badge/site-murilomunhao.github.io-58a6ff?style=flat-square)](https://murilomunhao.github.io/cpu-core-temps)

**Site:** https://murilomunhao.github.io/cpu-core-temps  
**Repositório:** https://github.com/murilomunhao/cpu-core-temps

---

## Para que serve

Monitorar a CPU sem abrir o System Monitor. O **CPU Core Temps** exibe na barra de tarefas a temperatura de cada **núcleo físico** (não das threads HT/SMT), com cores distintas e alerta visual quando a temperatura sobe.

Ideal para quem compila, joga ou simplesmente quer um olhar rápido no aquecimento real do processador — sem gráficos, sem popup obrigatório, só o texto que importa.

### Exemplo no painel

```text
C0:42°  C1:45°  C2:48°  C3:51°  C4:44°  C5:47°
```

| Estado | Faixa | Aparência |
|--------|--------|-----------|
| Normal | abaixo do aviso | Cor distinta por núcleo |
| Aviso | ≥ 75 °C (padrão) | Tons de laranja → vermelho |
| Crítico | ≥ 90 °C (padrão) | Vermelho intenso + negrito |

---

## Recursos

- **Só núcleos físicos** — usa a topologia do kernel (`thread_siblings`) para agrupar threads HT/SMT e mostrar um valor por núcleo real
- **Cores por núcleo** — cada núcleo com cor própria; alerta visual nos limites configuráveis
- **Leve e nativo** — QML + `ksystemstats` (mesma base do System Monitor)
- **Configurável** — limites de temperatura, intervalo, rótulos, separador e tamanho da fonte
- **Texto no painel** — sem depender de ícone + popup

---

## Requisitos

| Item | Observação |
|------|------------|
| **KDE Plasma 6** | Feito para Plasma 6 / Qt 6 |
| **ksystemstats / libksysguard** | Já inclusos numa instalação típica do Plasma |
| **lm_sensors** | Necessário para o kernel expor temperaturas (`sudo sensors-detect`) |

> **Nota:** em alguns processadores AMD o kernel só fornece temperatura de pacote (não por núcleo). Nesse caso o widget mostra a média disponível (`cpu/all/averageTemperature`).

---

### Instalar o plasmoid

Baixe o arquivo compactado na página de [Releases do GitHub](https://github.com/murilomunhao/cpu-core-temps/releases) e execute os seguintes comandos no terminal:

```bash
# Extrai o pacote e entra na pasta
unzip cpu-core-temps-v1.0.0.zip
cd cpu-core-temps-v1.0.0

# Da permissão de execução e instala
chmod +x install.sh
./install.sh
```

#### Instalação manual (opcional)

```bash
# Cria os diretórios necessários de forma segura
mkdir -p ~/.local/share/plasma/plasmoids
mkdir -p ~/.local/share/icons/hicolor/scalable/apps

# Remove versão anterior se existir para evitar pastas aninhadas
rm -rf ~/.local/share/plasma/plasmoids/com.github.murilomunhao.cpu-core-temps

# Copia os arquivos do plasmoid e o ícone do sistema
cp -r package ~/.local/share/plasma/plasmoids/com.github.murilomunhao.cpu-core-temps
cp package/contents/icons/com.github.murilomunhao.cpu-core-temps.svg ~/.local/share/icons/hicolor/scalable/apps/

# Reinicia o Plasma Shell para aplicar as alterações
systemctl restart --user plasma-plasmashell.service
```


Depois:

1. Botão direito na **barra de tarefas** → **Editar painel**
2. **Adicionar widgets** → procure por **CPU Core Temps**
3. Arraste para o painel

### Testar sem instalar

```bash
plasmawindowed com.github.murilomunhao.cpu-core-temps
```

(requer o pacote `plasma-sdk`)

---

## Como usar

1. **Instale** o plasmoid (comandos acima)
2. **Adicione** ao painel pelo editor de widgets
3. **Confirme os sensores** — se nada aparecer, rode `sensors` e configure o `lm_sensors`
4. **Ajuste** com botão direito no widget → **Configurar CPU Core Temps…**

### Verificar quantos núcleos físicos o sistema reporta

```bash
for d in /sys/devices/system/cpu/cpu[0-9]*; do
  [ -f "$d/topology/thread_siblings_list" ] || continue
  list=$(cat "$d/topology/thread_siblings_list")
  first=$(echo "$list" | cut -d, -f1 | cut -d- -f1)
  echo "$first"
done | sort -n | uniq
```

O número de linhas deve bater com a quantidade de `C0:`, `C1:`, … no widget.

---

## Configuração

| Opção | Padrão | Descrição |
|--------|--------|-----------|
| Temperatura de aviso | 75 °C | Inicia transição para tons de laranja/vermelho |
| Temperatura crítica | 90 °C | Vermelho intenso e negrito |
| Intervalo de atualização | 2 s | Frequência de leitura dos sensores |
| Rótulo do núcleo | Sim | Mostra `C0:`, `C1:`, … |
| Unidade (° ) | Sim | Exibe o símbolo de grau |
| Separador | espaço | Texto entre um núcleo e o próximo |
| Tamanho da fonte | auto (0) | `0` = fonte do tema; ou valor em px |

---

## Estrutura do projeto

```text
package/
├── metadata.json
├── LICENSE
└── contents/
    ├── config/
    │   ├── config.qml
    │   └── main.xml
    └── ui/
        ├── main.qml
        └── configGeneral.qml
```

**ID do plasmoid:** `com.github.murilomunhao.cpu-core-temps`

---

## 🤝 Contribuindo

Contribuições são sempre bem-vindas! Sinta-se à vontade para:

1. Reportar bugs
2. Sugerir novas funcionalidades
3. Enviar pull requests

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## ☕ Apoie o Projeto

Se este projeto te ajudou de alguma forma, considere fazer uma doação:

**PIX**: `536c8d7e-fb28-444f-8d58-7fd87397d401`

![](https://github.com/murilomunhao/boilerplate/blob/main/donate_pix_murilo.jpg)

---
Desenvolvido com ❤️ por Murilo Munhão
