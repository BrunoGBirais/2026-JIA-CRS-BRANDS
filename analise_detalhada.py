import pandas as pd
import openpyxl

arquivo = r'c:\Users\bruno.birais\Documents\CRS-Brants\6- Cenário de Demanda 15.06.2026.xlsx'

print("=" * 100)
print("ANÁLISE DETALHADA DA ABA 'METODOLOGIA'")
print("=" * 100)

# Ler a aba Metodologia
df = pd.read_excel(arquivo, sheet_name='Metodologia', header=None)

print(f"\nDimensões: {df.shape[0]} linhas x {df.shape[1]} colunas")

# Mostrar as primeiras 20 linhas e primeiras 15 colunas
print("\n" + "=" * 100)
print("PRIMEIRAS 20 LINHAS E 15 COLUNAS (para entender a estrutura):")
print("=" * 100)
print(df.iloc[:20, :15].to_string())

# Verificar se há texto explicativo nas primeiras colunas
print("\n" + "=" * 100)
print("ANÁLISE DAS PRIMEIRAS COLUNAS (coluna 0 a 3) - COMPLETO:")
print("=" * 100)
print(df.iloc[:30, :4].to_string())

# Verificar os headers (linha 4 parece ser o header)
print("\n" + "=" * 100)
print("HEADERS IDENTIFICADOS (linha 4):")
print("=" * 100)
headers = df.iloc[4, :].tolist()
for i, h in enumerate(headers[:20]):
    if pd.notna(h):
        print(f"Coluna {i}: {h}")

# Analisar o padrão das últimas colunas (parecem ser meses)
print("\n" + "=" * 100)
print("ÚLTIMAS 15 COLUNAS (parecem ser meses de forecast):")
print("=" * 100)
print(df.iloc[4:10, -15:].to_string())

# Verificar se existe alguma aba com explicação
print("\n" + "=" * 100)
print("VERIFICANDO ABA 'DASHBOARD' PARA POSSÍVEL EXPLICAÇÃO:")
print("=" * 100)
df_dash = pd.read_excel(arquivo, sheet_name='DASHBOARD', header=None)
print(df_dash.iloc[:25, :10].to_string())

# Verificar aba Relatório
print("\n" + "=" * 100)
print("VERIFICANDO ABA 'Relatório' PARA POSSÍVEL EXPLICAÇÃO:")
print("=" * 100)
df_rel = pd.read_excel(arquivo, sheet_name='Relatório', header=None)
print(df_rel.iloc[:25, :10].to_string())
