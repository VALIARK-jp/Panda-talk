export async function deleteSupabaseAuthUser(
  supabaseUrl: string,
  serviceRoleKey: string,
  userId: string
): Promise<void> {
  const base = supabaseUrl.replace(/\/$/, '')
  const response = await fetch(`${base}/auth/v1/admin/users/${userId}`, {
    method: 'DELETE',
    headers: {
      Authorization: `Bearer ${serviceRoleKey}`,
      apikey: serviceRoleKey,
    },
  })

  if (response.status === 404) return

  if (!response.ok) {
    const body = await response.text()
    throw new Error(`Failed to delete auth user (${response.status}): ${body}`)
  }
}
