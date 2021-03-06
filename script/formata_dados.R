library(readr)
library(dplyr)
library(tidyr)
options(scipen = 50)

# retorna um data frame com resumo mensal dos gastos de cada deputado

cria_tabela_final_gastos = function(dados){
  # antes de usar essa funcao o data frame dados deve estar no formato gerado pela
  # funcao prepara_tabela_final

  tabela_final_mensal = dados %>%
    #filter(vlrLiquido >= 0) %>%
    select(txNomeParlamentar, idecadastro, sgUF,  numAno, numMes, vlrLiquido) %>%
    group_by(txNomeParlamentar, idecadastro, sgUF, numAno, numMes) %>%
    summarise(total = sum(vlrLiquido)) %>%
    na.omit() %>%
    inner_join(cotas) %>%
    mutate(coef = total/cota_mensal)

  return(tabela_final_mensal)

}

formata_data_votacoes = function(votacoes){
  votacoes$diav = as.numeric(format(as.Date(votacoes$data, "%d/%m/%Y"), "%d"))
  votacoes$mesv = as.numeric(format(as.Date(votacoes$data, "%d/%m/%Y"), "%m"))
  votacoes$anov = as.numeric(format(as.Date(votacoes$data, "%d/%m/%Y"), "%Y"))

  votacoes = votacoes %>% select(-data)

  return(votacoes)
}

cria_tabela_final_categoria = function(dados){
  # antes de usar essa funcao o data frame dados deve estar no formato gerado pela
  # funcao prepara_tabela_final

  tabela_final_categoria = dados %>%
    filter(vlrLiquido > 0) %>%
    select(txNomeParlamentar, idecadastro, sgUF, numAno, numMes, nossas_categorias, vlrLiquido) %>%
    group_by(txNomeParlamentar, idecadastro, sgUF, numAno, numMes, nossas_categorias) %>%
    summarise(total = sum(vlrLiquido)) %>%
    na.omit() %>%
    inner_join(cotas) %>%
    mutate(coef = total/cota_mensal)

  return(tabela_final_categoria)
}

# retorna csv referente a presença dos deputados para votações em cada mês

cria_tabela_final_votacoes = function(votacoes){

  votacoes = votacoes %>%
    group_by(id_dep) %>%
    mutate(nome = first(nome))

  votacoes = votacoes %>%
    arrange(id_dep, anov, mesv, -diav) %>%
    group_by(id_dep, anov, mesv) %>%
    mutate(partido = first(partido))

  sessoes = votacoes %>%
    filter(anov > 2014) %>%
    select(anov, mesv, diav) %>%
    group_by(anov, mesv, diav) %>%
    distinct() %>%
    ungroup() %>%
    select(anov, mesv) %>%
    group_by(anov, mesv) %>%
    summarise(total_mes = n())

  tabela_final_votacoes = votacoes %>%
    filter(anov > 2014) %>%
    select(id_dep, anov, mesv, diav) %>%
    group_by(id_dep, anov, mesv, diav) %>%
    distinct() %>%
    ungroup() %>%
    select(id_dep, anov, mesv) %>%
    group_by(id_dep, anov, mesv) %>%
    summarise(total_deputado = n())

  tabela_final_votacoes = tabela_final_votacoes %>%
    select(mesv, anov, id_dep, total_deputado)

  return(tabela_final_votacoes)

}

# cria_tabela_gastos_presenca = function(tabela_final_votacoes, tabela_final_mensal){
#   ### TODO: adicionar partido quando o vereador não esteve presença no mês
#   names(tabela_final_mensal) = c("nome", "id", "uf", "ano", "mes", "total_gasto", "cota_mensal", "coef_gasto")
#   names(tabela_final_votacoes) = c("nome", "id", "partido", "uf","ano", "mes", "total_presenca", "total_mes", "coef_presenca")
#
#   sessoes = votacoes %>%
#     filter(anov > 2014) %>%
#     group_by(anov, mesv, diav) %>%
#     distinct() %>%
#     group_by(anov, mesv) %>%
#     summarise(total_mes = n())
#
#   tabela_gasto_presenca = tabela_final_mensal %>%
#                           full_join(tabela_final_votacoes[,2:9])
#
#   tabela_gasto_presenca$total_presenca[is.na(tabela_gasto_presenca$total_presenca)] = 0
#   tabela_gasto_presenca$coef_presenca[is.na(tabela_gasto_presenca$coef_presenca)] = 0
#
#   names(sessoes) = c("ano", "mes", "total_presenca_mes")
#
#   tabela_gasto_presenca = tabela_gasto_presenca %>%
#                           left_join(sessoes)
#   tabela_gasto_presenca$total_presenca_mes[is.na(tabela_gasto_presenca$total_presenca_mes)] = 0
#   tabela_gasto_presenca$total_mes = tabela_gasto_presenca$total_presenca_mes
#   tabela_gasto_presenca = tabela_gasto_presenca %>%
#                           ungroup() %>%
#                           select(-total_presenca_mes)
#
#   return(tabela_gasto_presenca)
# }

# retorna csv com a soma de todos os gastos e todas as cotas em cada ano

cria_tabela_gasto_total_anos = function(tabela_final_mensal) {

  names(tabela_final_mensal) = c("nome", "id", "uf", "ano", "mes", "total_gasto", "cota_mensal", "coef_gasto")

  gasto_total_anos = tabela_final_mensal %>%
    ungroup() %>%
    group_by(ano) %>%
    summarise(total_gasto = sum(total_gasto),
              total_disponivel = sum(cota_mensal))

  return(gasto_total_anos)
}

cria_tabela_6_gastos = function(dados){

  tabela_6_gastos = dados %>%
    #  filter(vlrLiquido >= 0) %>%
    select(idecadastro, txNomeParlamentar ) %>%
    group_by(idecadastro, txNomeParlamentar) %>%
    distinct()

  tabela_6_gastos = tabela_6_gastos %>%
    left_join(dados %>% filter(nossas_categorias == "Alimentação") %>%
                group_by(idecadastro, txNomeParlamentar) %>%
                summarise(Alimentação = sum(vlrLiquido)))

  tabela_6_gastos = tabela_6_gastos %>%
    left_join(dados %>% filter(nossas_categorias == "Combustíveis") %>%
                group_by(idecadastro, txNomeParlamentar) %>%
                summarise("Combustíveis" = sum(vlrLiquido)))

  tabela_6_gastos = tabela_6_gastos %>%
    left_join(dados %>% filter(nossas_categorias == "Locação de veículos") %>%
                group_by(idecadastro, txNomeParlamentar) %>%
                summarise("Locação de veículos" = sum(vlrLiquido)))

  tabela_6_gastos = tabela_6_gastos %>%
    left_join(dados %>% filter(nossas_categorias == "Passagens aéreas") %>%
                group_by(idecadastro, txNomeParlamentar) %>%
                summarise("Passagens aéreas" = sum(vlrLiquido)))

  tabela_6_gastos = tabela_6_gastos %>%
    left_join(dados %>% filter(nossas_categorias == "Escritório") %>%
                group_by(idecadastro, txNomeParlamentar) %>%
                summarise(Escritório = sum(vlrLiquido)))

  tabela_6_gastos = tabela_6_gastos %>%
    left_join(dados %>% filter(nossas_categorias == "Divulgação de atividade parlamentar") %>%
                group_by(idecadastro, txNomeParlamentar) %>%
                summarise("Divulgação de atividade parlamentar" = sum(vlrLiquido)))

  tabela_6_gastos[is.na(tabela_6_gastos)] = 0

  tabela_6_gastos$total = rowSums(tabela_6_gastos[,3:8] )

  return(tabela_6_gastos)

}

# retorna data frame com o total gasto em cada uma das principais categorias a cada mês.
# a coluna toal é referente ao total gasto em todas as categorias (inclusive as que não estão nessa tabela)

cria_tabela_6_gastos_mensal = function(dados, tabela_final_mensal){

  tabela_6_gastos_mensal = dados %>%
    #  filter(vlrLiquido >= 0) %>%
    select(idecadastro, txNomeParlamentar, numAno, numMes ) %>%
    group_by(idecadastro, txNomeParlamentar, numAno, numMes) %>%
    distinct()

  tabela_6_gastos_mensal = tabela_6_gastos_mensal %>%
    left_join(dados %>% filter(nossas_categorias == "Alimentação") %>%
                group_by(idecadastro, txNomeParlamentar, numAno, numMes) %>%
                summarise(Alimentação = sum(vlrLiquido)))

  tabela_6_gastos_mensal = tabela_6_gastos_mensal %>%
    left_join(dados %>% filter(nossas_categorias == "Combustíveis") %>%
                group_by(idecadastro, txNomeParlamentar, numAno, numMes) %>%
                summarise("Combustíveis" = sum(vlrLiquido)))

  tabela_6_gastos_mensal = tabela_6_gastos_mensal %>%
    left_join(dados %>% filter(nossas_categorias == "Locação de veículos") %>%
                group_by(idecadastro, txNomeParlamentar, numAno, numMes) %>%
                summarise("Locação de veículos" = sum(vlrLiquido)))

  tabela_6_gastos_mensal = tabela_6_gastos_mensal %>%
    left_join(dados %>% filter(nossas_categorias == "Passagens aéreas") %>%
                group_by(idecadastro, txNomeParlamentar, numAno, numMes) %>%
                summarise("Passagens aéreas" = sum(vlrLiquido)))

  tabela_6_gastos_mensal = tabela_6_gastos_mensal %>%
    left_join(dados %>% filter(nossas_categorias == "Escritório") %>%
                group_by(idecadastro, txNomeParlamentar, numAno, numMes) %>%
                summarise(Escritório = sum(vlrLiquido)))

  tabela_6_gastos_mensal = tabela_6_gastos_mensal %>%
    left_join(dados %>% filter(nossas_categorias == "Divulgação de atividade parlamentar") %>%
                group_by(idecadastro, txNomeParlamentar, numAno, numMes) %>%
                summarise("Divulgação de atividade parlamentar" = sum(vlrLiquido)))

  tabela_6_gastos_mensal[is.na(tabela_6_gastos_mensal)] = 0

  tabela_6_gastos_mensal = tabela_6_gastos_mensal %>%
    left_join(tabela_final_mensal %>%
                group_by(idecadastro, txNomeParlamentar, numAno, numMes) %>%
                summarise("total" = sum(total)))

  # tabela_6_gastos_mensal$total = rowSums(tabela_6_gastos_mensal[,5:10] )

  return(tabela_6_gastos_mensal)

}

cria_top_estourados_estado = function(estado, tabela_final_mensal) {

  estourados = tabela_final_mensal%>%
    ungroup() %>%
    filter (sgUF == estado) %>%
    arrange(-coef) %>%
    slice(1:10)

  return(estourados)

}

cria_top_estourados = function(tabela_final_mensal) {

  estourados = tabela_final_mensal%>%
    ungroup() %>%
    arrange(-coef) %>%
    slice(1:10)

  return(estourados)

}

#########################################################################################

# retorna um data frame de 3 colunas com ano, mes e quantidade e sessões

cria_sessoes_mensal = function(votacoes) {
  sessoes = votacoes %>%
    filter(anov > 2014) %>%
    # group_by(anov, mesv, diav) %>%
    # distinct() %>%
    # group_by(anov, mesv) %>%
    # summarise(total_mes = n())

    select(anov, mesv, diav) %>%
    group_by(anov, mesv, diav) %>%
    distinct() %>%
    ungroup() %>%
    select(anov, mesv) %>%
    group_by(anov, mesv) %>%
    summarise(total_mes = n())

  sessoes = sessoes %>%
    select(mesv, anov, total_mes)



  return(sessoes)
}

# retorna um data frame de duas colunas com cnpj e nome de empresas
# empresas sem cnpj tem este campo zerado
# para empresas que possuem mais de um nome para o mesmo cnpj, apenas um deles foi selecionado e atribuído para todos

cria_empresas = function(dados){
  empresas = dados %>%
    filter(!is.na(txtCNPJCPF)) %>%
    select(txtCNPJCPF, txtFornecedor) %>%
    group_by(txtCNPJCPF) %>%
    mutate(txtFornecedor = first(txtFornecedor)) %>%
    group_by(txtCNPJCPF, txtFornecedor) %>%
    #  summarise(n = n())
    distinct()

  empresas.na = dados %>%
    filter(is.na(txtCNPJCPF)) %>%
    select(txtCNPJCPF, txtFornecedor) %>%
    group_by(txtFornecedor) %>%
    distinct() %>%
    mutate(txtCNPJCPF = "00000000000000")

  empresas = empresas %>%
    rbind(empresas.na)

  empresas$idEmpresa = rownames(empresas)

  return(empresas)
}

# retorna data frame com cada gastos.
# Há colunas para nome, idecadastro, UF,  ano, mes, valor, Empresa, cnpj e categoria
#idDocumento: idDeputado: mesEmissao:	anoEmissao: nomeCategoria: idCategoria: nomeFornecedor: valor: cnpj:
cria_tabela_gastos_empresas = function(dados, empresas) {

  tabela_gastos_empresas =  dados %>%
    filter(!is.na(txtCNPJCPF)) %>%
    select(idecadastro,numAno, numMes, vlrLiquido, txtCNPJCPF, nossas_categorias) %>%
    left_join(empresas)

  tabela_gastos_empresas.na =  dados %>%
    filter(is.na(txtCNPJCPF)) %>%
    select(idecadastro, numAno, numMes, vlrLiquido, txtFornecedor, nossas_categorias) %>%
    left_join(empresas %>% filter(txtCNPJCPF == "00000000000000"))

  tabela_gastos_empresas = tabela_gastos_empresas %>%
    rbind(tabela_gastos_empresas.na) %>%
    select(idecadastro, numAno, numMes, idEmpresa, txtCNPJCPF, txtFornecedor, nossas_categorias, vlrLiquido) %>%
    group_by(idecadastro, numAno, numMes, idEmpresa, txtCNPJCPF, txtFornecedor, nossas_categorias) %>%
    summarise(total = sum(vlrLiquido))

  tabela_gastos_empresas$id = rownames(tabela_gastos_empresas)
  #tabela_gastos_empresas$id = 0

  names(tabela_gastos_empresas)[2:3] = c("ano", "mes")
  #tabela_gastos_empresas = select(idecadastro, numAno, numMes, idEmpresa, txtCNPJCPF, txtFornecedor, nossas_categorias, total, id)

  return(tabela_gastos_empresas)
}

cria_tabela_info_deputados = function(info_deputados, twitter_profiles, dados){
  names(twitter_profiles)[3] = c("idecadastro")
  names(info_deputados)[1] = c("idecadastro")

  ultimos_partidos = dados %>%
    ungroup() %>%
    arrange(idecadastro, -numAno, -numMes) %>%
    group_by(idecadastro, txNomeParlamentar) %>%
    summarise(sgPartido = first(sgPartido))

  names(ultimos_partidos)[1] = c("idecadastro")

  tabela_info_pessoais = dados %>% select(idecadastro, txNomeParlamentar, sgUF) %>% distinct() %>%
    left_join(ultimos_partidos) %>%
    left_join(info_deputados %>% select(idecadastro, urlFoto, fone, email)) %>%
    left_join(twitter_profiles %>% select(idecadastro, twitter_profile))

  tabela_info_pessoais = tabela_info_pessoais %>%
    select(idecadastro, txNomeParlamentar, sgPartido, sgUF, urlFoto, twitter_profile, fone, email)

  # (id, nome, partidoAtual, uf, foto, twitter, telefone, email, dataNasc);
  # "idecadastro","txNomeParlamentar","sgUF","sgPartido","urlFoto","fone","email","twitter_profile"

  return(tabela_info_pessoais)
}


cria_ganhadores_selos = function(tabela_6_gastos_mensal, tabela_final_votacoes){

  ganhadores_selos = tabela_6_gastos_mensal %>% select(-total) %>%
    gather("categoria", "valor", 5:10) %>%
    group_by(numAno, numMes, categoria) %>%
    mutate("mediana" = median(valor)) %>%
    filter(valor > mediana)

  ganhadores_selos = ganhadores_selos %>% select(idecadastro, numMes, numAno, categoria)
  return(ganhadores_selos)

  # mediana_gastos = tabela_6_gastos_mensal %>%
  #   ungroup() %>%
  #   select(-idecadastro, -txNomeParlamentar, -total) %>%
  #   group_by(numAno, numMes) %>%
  #   summarise("Alimentação" = median(`Alimentação`),
  #          "Combustíveis" = median(`Combustíveis`),
  #          "Locação de veículos" = median(`Locação de veículos`),
  #          "Passagens aéreas" = median(`Passagens aéreas`),
  #          "Escritório" = median(`Escritório`),
  #          "Divulgação de atividade parlamentar" = median(`Divulgação de atividade parlamentar`)) %>%
  #   gather("categoria", "valor", 3:8)

}

cria_tabela_selos_presencas = function(tabela_final_gastos, tabela_final_votacoes, sessoes_mensal){
  
  tabela_selos_votacoes = tabela_final_gastos %>% filter(numMes != 1)
  names(tabela_selos_votacoes)[2] = c("id_dep")
  names(tabela_selos_votacoes)[4:5] = c("anov", "mesv")
  
  
  tabela_selos_votacoes = sessoes_mensal %>% left_join(tabela_selos_votacoes %>% ungroup() %>% select(id_dep, anov, mesv)) %>%
    left_join(tabela_final_votacoes)
  
  tabela_selos_votacoes$total_deputado[is.na(tabela_selos_votacoes$total_deputado)] = 0
  
  tabela_selos_votacoes$selo = NA
  tabela_selos_votacoes$selo[(tabela_selos_votacoes$total_deputado/tabela_selos_votacoes$total_mes) > 0.75] = "batedor"
  tabela_selos_votacoes$selo[(tabela_selos_votacoes$total_deputado/tabela_selos_votacoes$total_mes) < 0.25] = "gaspar"
  tabela_selos_votacoes$selo[is.na(tabela_selos_votacoes$selo)] = "-"
  
  tabela_selos_votacoes$id = 0
  
  tabela_selos_votacoes = tabela_selos_votacoes %>%
    select(id_dep, anov, mesv, selo)
  
  return(tabela_selos_votacoes)
}

cria_tabela_selos_cota = function(tabela_final_gastos) {

  tabela_selos_cota = tabela_final_gastos %>% ungroup()
  
  tabela_selos_cota$selo = NA
  tabela_selos_cota$selo[tabela_selos_cota$coef > 1] = "camarote"
  tabela_selos_cota$selo[tabela_selos_cota$coef <= 1] = "moderado"
  
  #tabela_selos_cota$id = 0
  
  tabela_selos_cota = tabela_selos_cota %>%
    select(id, idecadastro, numAno, numMes, selo)
  
  return(tabela_selos_cota)
}