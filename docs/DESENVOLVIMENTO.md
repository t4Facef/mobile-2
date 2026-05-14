# Guia de Desenvolvimento em Grupo

> Fluxo de trabalho, checklist e práticas | RouteAI — Mobile 1 Facef 2026

---

## Checklist do projeto

### Estrutura base
- [ ] Definir estrutura de pastas do projeto
- [ ] Adicionar dependências no `pubspec.yaml`
- [ ] Criar os models de dados (o que é uma "entrega"?)
- [ ] Configurar navegação entre as telas principais
- [ ] Montar lista de entregas com dados fictícios na tela

### Mapa e geolocalização
- [ ] Adicionar mapa na tela
- [ ] Exibir localização atual do entregador no mapa
- [ ] Exibir pontos de entrega como marcadores no mapa
- [ ] Testar no smartphone real (não só no emulador)

### Integração com IA
- [ ] Criar o serviço que chama a API de IA
- [ ] Montar o prompt com dados das entregas + localização atual
- [ ] Exibir ordem sugerida + justificativa da IA na tela
- [ ] Atualizar marcadores/rota no mapa conforme a sugestão

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

### Branches

```
main                          ← código estável, o que vai pra apresentação
├── feature/nome-da-feature   ← desenvolvimento de funcionalidades
└── fix/nome-do-bug           ← correções
```

Não commitar direto na `main`. Sempre criar branch, desenvolver, e mergear depois de um colega dar uma olhada rápida.

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

1. Push da branch para o GitHub
2. Clicar em **"Compare & pull request"**
3. Título direto: `feat: mapa com posição do entregador`
4. Descrever o que foi feito e como testar
5. Pedir pra alguém do time revisar antes de mergear na `main`

---

## Práticas gerais de Flutter

- Estado local do widget → `StatefulWidget`; estado compartilhado entre telas → gerenciador de estado (a definir conforme avança)
- Lógica de negócio e chamadas a APIs **fora** dos widgets, em classes separadas
- Widgets com `build()` longo (mais de ~60 linhas) → extrair em arquivo próprio
- Rodar `flutter analyze` antes de cada merge
- Testar no dispositivo real a partir do mapa — emulador não representa GPS real
