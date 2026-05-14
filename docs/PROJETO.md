# Projeto — RouteAI

## O que é

App mobile para entregadores. O entregador vê a lista de entregas do dia e a IA sugere a melhor ordem de execução considerando tempo de espera do cliente, tipo de produto (ex: sorvete tem prioridade) e otimização de rota. O mapa exibe a rota sugerida em tempo real.

## Requisitos da atividade

| Requisito | Como vamos atender |
|---|---|
| Mapa na interface | Mapa com os pontos de entrega e rota |
| Geolocalização com benefício prático | Posição atual do entregador + ordenação de rota |
| Integração com API de IA | IA recebe lista de entregas + localização e retorna ordem sugerida com justificativa |
| Funcional no smartphone | Testar no device real desde cedo |

## Fluxo principal

1. Entregador abre o app e vê a lista de entregas pendentes
2. Cada entrega tem: endereço, cliente, hora do pedido, tipo de produto
3. Botão **"Organizar com IA"** manda os dados para a API de IA
4. A IA retorna a ordem sugerida com uma breve justificativa
5. O mapa exibe a rota na nova ordem
6. Entregador marca cada entrega como concluída
