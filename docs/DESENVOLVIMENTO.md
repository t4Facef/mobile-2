# Guia de Desenvolvimento em Grupo

> Fluxo de trabalho, checklist e práticas | RouteAI — Mobile 1 Facef 2026

---

## Arquitetura — MVVM

O projeto segue o padrão **MVVM (Model — View — ViewModel)**, que se encaixa naturalmente no modelo reativo do Flutter.

| Camada | Responsabilidade | Onde fica |
|---|---|---|
| **Model** | Estrutura de dados, sem lógica | `lib/models/` |
| **ViewModel** | Estado da tela + lógica de negócio + chama Services | `lib/viewmodels/` |
| **View** | Widgets — só exibem o que o ViewModel expõe | `lib/views/` |

Os **Services** (GPS, IA, mapas) ficam em `lib/services/` e são chamados pelo ViewModel — não pertencem a nenhuma das três camadas do MVVM, são dependências externas delas.

A View nunca chama um Service diretamente. Ela fala só com o ViewModel, que coordena tudo.

### Estrutura de pastas

> Cada pasta em `lib/` tem um arquivo placeholder com um comentário explicando o que aquela camada faz e como ela se conecta à arquitetura. São ponto de partida — os arquivos reais vão sendo criados na mesma pasta conforme a implementação avança.

```
lib/
├── main.dart
├── models/
│   └── example_model.dart      # placeholder
├── services/
│   └── example_service.dart    # placeholder
├── viewmodels/
│   └── example_viewmodel.dart  # placeholder
├── views/
│   └── example_view.dart       # placeholder
└── widgets/
    └── example_widget.dart     # placeholder
```

Cada pasta tem um arquivo `example_*.dart` com um comentário explicando o papel daquela camada e como ela se conecta às outras. Ao implementar, crie os arquivos reais na mesma pasta — os placeholders podem ser deletados quando não forem mais necessários como referência.

---

## Checklist do projeto

### Estrutura base
- [ ] Criar estrutura de pastas conforme o MVVM acima
- [ ] Adicionar dependências no `pubspec.yaml`
- [ ] Criar o model `Delivery` (endereço, cliente, hora do pedido, tipo de produto)
- [ ] Criar `DeliveryViewModel` com lista fictícia de entregas
- [ ] Configurar navegação entre as telas principais
- [ ] Montar lista de entregas na `HomeView`

### Mapa e geolocalização
- [ ] Adicionar mapa na `MapView`
- [ ] Criar `LocationService` e exibir posição atual do entregador no mapa
- [ ] Exibir pontos de entrega como marcadores
- [ ] Testar no smartphone real (não só no emulador)

### Integração com IA
- [ ] Criar `AiService` com chamada à API de IA
- [ ] Montar prompt com dados das entregas + localização atual
- [ ] Atualizar `DeliveryViewModel` com a ordem sugerida
- [ ] Exibir justificativa da IA na tela

### UI e polimento
- [ ] Revisar layout (espaçamentos, cores, legibilidade)
- [ ] Tratar erros básicos (sem internet, GPS desligado)
- [ ] Marcar entrega como concluída e atualizar a lista
- [ ] Testar fluxo completo no smartphone da apresentação

### Baixa prioridade
- [ ] Login / autenticação de usuário
- [ ] Backend próprio ou banco de dados remoto
- [ ] Histórico de entregas persistido
- [ ] Notificações push
- [ ] Cálculo de tempo real de trânsito

---

## Organização Git

### Estrutura de branches

```
main                        ← código estável, o que vai pra apresentação
├── nome-da-feature ← desenvolvimento de funcionalidades
└── fix/nome-do-bug         ← correções pontuais
```

O nome da branch deve descrever o que está sendo feito. Exemplos:

```bash
delivery-list       # tela de lista de entregas
map-geolocation     # mapa + localização
ai-integration      # integração com a API de IA
gps-permission-crash    # correção de bug específico
```

Não commitar direto na `main`. Cada feature tem sua branch, e só entra na `main` depois de um colega revisar.

### Configurando o repositório (quem cria)

```bash
git init
git remote add origin https://github.com/usuario/mobile_2_bim.git
git add .
git commit -m "chore: estrutura inicial do projeto"
git push -u origin main
```

### Cada pessoa clona e cria sua branch

```bash
git clone https://github.com/usuario/mobile_2_bim.git
cd mobile_2_bim

# Criar branch a partir da main atualizada
git checkout main
git pull origin main
git checkout -b feature/nome-da-feature
```

### Fluxo diário

```bash
# Antes de começar — sincronizar com o que o time fez
git checkout main
git pull origin main
git checkout feature/nome-da-feature
git merge main

# Salvando progresso
git status
git add lib/services/ai_service.dart
git commit -m "feat: cria serviço de chamada para API de IA"
git push origin feature/nome-da-feature
```

### Mensagens de commit

| Prefixo | Quando usar |
|---|---|
| `feat:` | nova funcionalidade |
| `fix:` | correção de bug |
| `style:` | ajuste visual, espaçamento |
| `refactor:` | refatoração sem mudar comportamento |
| `docs:` | documentação |
| `chore:` | dependências, configuração |

### Abrindo Pull Request

```bash
# Garantir que a branch está atualizada antes de abrir o PR
git checkout main
git pull origin main
git checkout feature/nome-da-feature
git merge main

# Resolver conflitos se houver, então:
git push origin feature/nome-da-feature
```

1. Abrir o GitHub → clicar em **"Compare & pull request"** na branch
2. Título direto: `feat: mapa com posição do entregador`
3. Descrever o que foi feito e como testar
4. Pedir pra alguém do time revisar antes de mergear na `main`

---

## Práticas gerais de Flutter

- A **View** nunca chama Service diretamente — sempre passa pelo ViewModel
- Estado local do widget → `StatefulWidget`; estado compartilhado entre telas → ViewModel
- Widgets com `build()` longo (mais de ~60 linhas) → extrair em arquivo próprio em `widgets/`
- Rodar `flutter analyze` antes de cada merge
- Testar no dispositivo real a partir do mapa — emulador não representa GPS real
