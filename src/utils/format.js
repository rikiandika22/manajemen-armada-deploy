export function formatRupiah(value) {
  if (value === null || value === undefined || value === '') return '-';
  const numberValue = Number(value);
  if (Number.isNaN(numberValue)) return '-';
  
  // Format as IDR without decimals
  const formatted = new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(numberValue);

  // Clean up any extra spaces the browser Intl might inject
  return formatted.replace(/Rp\s?/, 'Rp ');
}
